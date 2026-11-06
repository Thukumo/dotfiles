{
  config,
  lib,
  ...
}:
let
  access = config.custom.secrets.access;
  homeUsers = config.home-manager.users or { };

  # Runtime locations of every declared secret. Home-manager's secretsDir is
  # expanded from XDG_RUNTIME_DIR at activation time, so turn it into the
  # /run/user/* glob that AppArmor can match.
  homeRuntimeDir =
    hm:
    let
      dir = toString (hm.age.secretsDir or "/run/user/*/agenix");
    in
    lib.replaceStrings [ "\${XDG_RUNTIME_DIR}" ] [ "/run/user/*" ] dir;

  systemEntries = lib.mapAttrsToList (
    name: secret:
    let
      a = access.system.${name} or null;
      kind = if a == null then "root" else a.kind;
      credentialDirs =
        if kind == "credential" && a != null then
          map (unit: "/run/credentials/${unit}.service/**") a.consumers
        else
          [ ];
      # agenix symlinks secretsDir to secretsMountPoint/<generation>; the
      # resolved path must be covered too or the deny is bypassed.
      generation = if secret.symlink then "${config.age.secretsMountPoint}/*/${secret.name}" else null;
      # The raw agenix path is the source for LoadCredential; a credential
      # consumer must not be able to read it directly.
      paths = lib.unique (
        [ secret.path ] ++ lib.optional (generation != null) generation ++ credentialDirs
      );
    in
    {
      inherit paths;
      inherit kind;
      owner = if a == null then null else a.owner;
      allowed =
        if kind == "credential" then
          credentialDirs
        else
          lib.unique ([ secret.path ] ++ lib.optional (generation != null) generation);
      programs = if a == null then [ ] else a.programs;
      protected = a == null || (a.acceptedRisk or null) == null;
    }
  ) config.age.secrets;

  homeEntries = lib.concatLists (
    lib.mapAttrsToList (
      user: hm:
      let
        runtimeDir = homeRuntimeDir hm;
        homeDir = hm.home.homeDirectory;
      in
      lib.mapAttrsToList (
        name: secret:
        let
          a = (access.home.${user} or { }).${name} or null;
          runtimeName = secret.name or name;
          runtime = "${runtimeDir}/${runtimeName}";
          # agenix rotates /run/user/<uid>/agenix -> agenix.d/<generation>;
          # both spellings must be denied/allowed or the rule is bypassed.
          generation =
            if lib.hasSuffix "/agenix" runtimeDir then
              "${lib.removeSuffix "/agenix" runtimeDir}/agenix.d/*/${runtimeName}"
            else
              null;
          link =
            if a != null && a.path != null && a.path != "" then
              if lib.hasPrefix "/" a.path then a.path else "${homeDir}/${a.path}"
            else
              null;
          paths = lib.unique (
            [ runtime ] ++ lib.optional (generation != null) generation ++ lib.optional (link != null) link
          );
        in
        {
          inherit paths user;
          allowed = paths;
          consumers = if a == null then [ ] else a.consumers;
          programs = if a == null then [ ] else a.programs;
          protected = a == null || (a.acceptedRisk or null) == null;
        }
      ) (hm.age.secrets or { })
    ) homeUsers
  );

  entries = systemEntries ++ homeEntries;

  # Protected home secrets without a consumer: only these need to be hidden
  # from systemd --user. Consumer-delivered secrets must stay readable by the
  # user manager (EnvironmentFile/--env-file).
  homeProtectedPaths = lib.unique (
    lib.concatMap (entry: if entry.protected then entry.paths else [ ]) homeEntries
  );

  homeDirectProtectedPaths = lib.unique (
    lib.concatMap (
      entry: if entry.protected && entry.consumers == [ ] then entry.paths else [ ]
    ) homeEntries
  );

  # Identity keys decrypt all secrets, so treat them as secrets too.
  # /persist is an implementation detail of impermanence; deny both spellings.
  bothPersistPaths =
    path:
    let
      p = toString path;
    in
    [ p ]
    ++ lib.optional (lib.hasPrefix "/persist/" p) (lib.removePrefix "/persist" p)
    ++ lib.optional (!lib.hasPrefix "/persist/" p) "/persist${p}";

  systemIdentityPaths = lib.unique (lib.concatMap bothPersistPaths config.age.identityPaths);
  homeIdentityPaths = lib.unique (
    lib.concatMap (hm: lib.concatMap bothPersistPaths (hm.age.identityPaths or [ ])) (
      lib.attrValues homeUsers
    )
  );
  identityPaths = lib.unique (systemIdentityPaths ++ homeIdentityPaths);

  # System secrets are normally protected by service-user ownership. The
  # exception is kind = "owner" with a normal-user owner.
  isNormalOwner =
    owner:
    owner != null
    && owner != "root"
    && owner != "0"
    && builtins.hasAttr owner config.users.users
    && config.users.users.${owner}.isNormalUser;

  systemUserProtectedPaths = lib.unique (
    lib.concatMap (
      entry:
      if entry.protected && entry.kind == "owner" && isNormalOwner entry.owner then entry.paths else [ ]
    ) systemEntries
  );

  protectedPaths = lib.unique (
    lib.concatMap (entry: if entry.protected then entry.paths else [ ]) entries ++ identityPaths
  );

  fallbackProtectedPaths = lib.unique (
    homeProtectedPaths ++ systemUserProtectedPaths ++ identityPaths
  );

  serviceProtectedPaths = lib.unique (
    homeDirectProtectedPaths ++ systemUserProtectedPaths ++ identityPaths
  );

  programNames = lib.unique (lib.concatMap (entry: entry.programs) entries);

  # AppArmor profiles are per executable, not per invocation. General-purpose
  # interactive programs can print or copy their own secrets (nix config show,
  # gh auth token, ssh ProxyCommand) and are therefore not treated as a
  # boundary. Their secrets are marked acceptedRisk and are not denied.
  skippedPrograms = [
    "ssh"
    "ssh-keygen"
    "gh"
    "nix"
    "opencode"
    "nowplaying-client"
    "podman"
    "vpn-sstp-connect"
  ];
  profiledPrograms = lib.filter (name: !(builtins.elem name skippedPrograms)) programNames;

  # An AppArmor profile is per executable, not per user. If the same program
  # is used by two users' home secrets, one profile would allow both users'
  # secrets, so refuse to pretend it is isolated.
  sharedPrograms = lib.filter (
    program:
    lib.length (
      lib.unique (
        lib.concatMap (
          entry:
          if entry ? user && entry.protected && builtins.elem program entry.programs then
            [ entry.user ]
          else
            [ ]
        ) homeEntries
      )
    ) > 1
  ) programNames;

  allowedPaths =
    program:
    lib.unique (
      lib.concatMap (
        entry: if entry.protected && builtins.elem program entry.programs then entry.allowed else [ ]
      ) entries
    );

  deniedPaths =
    program: lib.filter (path: !(builtins.elem path (allowedPaths program))) protectedPaths;

  # Read-only deny; agenix must still be able to write the decrypted files.
  denyReadRules = paths: lib.concatMapStringsSep "\n" (path: "  deny \"${path}\" r,") paths;

  # Dedicated service daemons only. `all` keeps the daemon working; the deny
  # rules remove access to secrets that do not belong to it.
  makeProfile =
    name:
    let
      denyRules = lib.concatMapStringsSep "\n" (path: "  deny \"${path}\" rwklmx,") (deniedPaths name);
    in
    ''
      # Dedicated service daemon profile generated from custom.secrets.access.
      abi <abi/5.0>,

      include <tunables/global>

      profile ${name} /nix/store/*/bin/${name} {
        all,
        "/run/nscd/socket" rw,
      ${denyRules}
      }
    '';

  # fallback and systemd-user share the same broad rule set; only the deny
  # list differs. Keeping the block in one place avoids drift.
  broadRules = ''
    /** rwklm,
    /** pix,
    capability,
    network,
    unix,
    dbus,
    signal,
    ptrace,
    mount,
    umount,
    remount,
    pivot_root,
    userns,
    io_uring,
    mqueue,
    "/run/nscd/socket" rw,
    # Let the user/system executor attach the trusted agenix profile to the
    # home-manager agenix service. The profile is not attached to any binary.
    change_profile -> agenix,
  '';

  makeBroadProfile =
    {
      name,
      attachment ? "",
      deny,
    }:
    ''
      # The broad profile is a secret deny-list, not a general sandbox.
      abi <abi/5.0>,

      include <tunables/global>

      profile ${name}${attachment} flags=(attach_disconnected) {
        ${broadRules}
      ${denyReadRules deny}
      }
    '';

  makeFallbackProfile = makeBroadProfile {
    name = "fallback";
    attachment = " /**";
    deny = fallbackProtectedPaths;
  };

  makeSystemdUserProfile = makeBroadProfile {
    name = "systemd-user";
    deny = serviceProtectedPaths;
  };

  # The global age/ragenix profiles are needed by the system activation, which
  # runs as root. They may read the system identity key (root-only), but must
  # not read the home identity key or plaintext home secrets: otherwise any
  # unconfined process could run age with the user's key and decrypt
  # everything. Home secrets are decrypted by the trusted agenix user service.
  makeSystemIdentityToolProfile = tool: ''
    abi <abi/5.0>,

    include <tunables/global>

    profile ${tool} /nix/store/*/bin/${tool} {
      all,
      "/run/nscd/socket" rw,
    ${denyReadRules (lib.unique (homeIdentityPaths ++ homeProtectedPaths ++ systemUserProtectedPaths))}
    }
  '';

  # Trusted only through AppArmorProfile= on the home-manager agenix service.
  makeAgenixProfile = ''
    abi <abi/5.0>,

    include <tunables/global>

    profile agenix flags=(attach_disconnected) {
      all,
      "/run/nscd/socket" rw,
    }
  '';

  invalidProgramNames = lib.filter (
    name: builtins.match "[A-Za-z0-9][A-Za-z0-9._+-]*" name == null
  ) programNames;
in
{
  security.apparmor = {
    enable = true;
    killUnconfinedConfinables = false;
    policies =
      lib.listToAttrs (
        map (name: {
          inherit name;
          value = {
            state = "enforce";
            profile = makeProfile name;
          };
        }) profiledPrograms
      )
      // {
        age = {
          state = "complain";
          profile = makeSystemIdentityToolProfile "age";
        };
        ragenix = {
          state = "complain";
          profile = makeSystemIdentityToolProfile "ragenix";
        };
        agenix = {
          state = "enforce";
          profile = makeAgenixProfile;
        };
        fallback = {
          state = "complain";
          profile = makeFallbackProfile;
        };
        systemd-user = {
          # Best-effort only: complain keeps the user manager from reading
          # identity keys, but systemd-run can still select unconfined.
          state = "complain";
          profile = makeSystemdUserProfile;
        };
      };
  };

  # Consumer secrets (EnvironmentFile/--env-file) must be readable by the
  # user manager on every host, not only mouse-3.
  systemd.services."user@".serviceConfig.AppArmorProfile = "systemd-user";

  assertions = [
    {
      assertion = invalidProgramNames == [ ];
      message = "custom.secrets.access: program names must be executable basenames matching [A-Za-z0-9][A-Za-z0-9._+-]*: ${lib.concatStringsSep ", " invalidProgramNames}";
    }
    {
      assertion = sharedPrograms == [ ];
      message = "custom.secrets.access: the same program is used by home secrets of multiple users (${lib.concatStringsSep ", " sharedPrograms}); AppArmor profiles are per executable and cannot isolate users";
    }
    {
      assertion = !(builtins.elem "fallback" programNames);
      message = "custom.secrets.access: 'fallback' is reserved for the AppArmor fallback profile";
    }
    {
      assertion = !(builtins.elem "systemd-user" programNames);
      message = "custom.secrets.access: 'systemd-user' is reserved for the systemd user manager profile";
    }
    {
      assertion = !(builtins.elem "agenix" programNames);
      message = "custom.secrets.access: 'agenix' is reserved for the trusted agenix service profile";
    }
    {
      assertion = !(builtins.elem "age" programNames || builtins.elem "ragenix" programNames);
      message = "custom.secrets.access: 'age' and 'ragenix' are reserved for identity-key handling";
    }
  ];
}
