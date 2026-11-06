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

  # Root/service-user-owned system secrets are left to DAC so boot activation
  # keeps working; fallback also hides identity keys and the separate
  # systemUserProtectedPaths below.
  homeProtectedPaths = lib.unique (
    lib.concatMap (entry: if entry.protected then entry.paths else [ ]) homeEntries
  );

  # Secrets with consumers are read by systemd/podman (EnvironmentFile /
  # --env-file); the systemd --user profile must leave those readable.
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

  identityPaths = lib.unique (
    lib.concatMap bothPersistPaths config.age.identityPaths
    ++ lib.concatMap (hm: lib.concatMap bothPersistPaths (hm.age.identityPaths or [ ])) (
      lib.attrValues homeUsers
    )
  );

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

  # nix is shared by nix-daemon/nix-store/nix-env; complain +
  # attach_disconnected avoids breaking them while explicit deny still works.
  programFlags = {
    nix = " flags=(attach_disconnected)";
  };
  programStates = {
    nix = "complain";
  };

  # shortcut: this is secret isolation, not a general sandbox; `all` permits
  # everything except the deny rules. Upgrade to deny-by-default if full
  # confinement is needed.
  makeProfile =
    name:
    let
      denyRules = lib.concatMapStringsSep "\n" (path: "  deny \"${path}\" rwklmx,") (deniedPaths name);
    in
    ''
      # all keeps the program working; the deny rules are the secret access
      # matrix from custom.secrets.access. Child processes inherit this
      # profile, so they cannot exec their way around the deny rules. Add the
      # parent program to a secret if a delegated child needs it.
      abi <abi/5.0>,

      include <tunables/global>

      profile ${name} /nix/store/*/bin/${name}${programFlags.${name} or ""} {
        all,
        # nscd lives outside the DynamicUser mount namespace; all alone
        # cannot resolve this disconnected path.
        "/run/nscd/socket" rw,
      ${denyRules}
      }
    '';

  # Read-only deny; agenix must still be able to write the decrypted files.
  denyReadRules = paths: lib.concatMapStringsSep "\n" (path: "  deny \"${path}\" r,") paths;

  # Complain mode still enforces explicit deny rules, but allows missing
  # permissions. attach_disconnected is needed for dbus-broker/podman, which
  # resolve paths from their own mount namespaces.
  makeFallbackProfile = ''
    # fallback catches every executable without a more specific profile.
    abi <abi/5.0>,

    include <tunables/global>

    profile fallback /** flags=(attach_disconnected) {
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
    ${denyReadRules fallbackProtectedPaths}
    }
  '';

  # systemd --user reads EnvironmentFile secrets and launches user services.
  # It is explicitly allowed to read consumer-delivered secrets.
  makeSystemdUserProfile = ''
    # systemd --user and podman need attach_disconnected for their namespaces.
    abi <abi/5.0>,

    include <tunables/global>

    profile systemd-user flags=(attach_disconnected) {
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
    ${denyReadRules serviceProtectedPaths}
    }
  '';

  # podman reads --env-file and needs attach_disconnected for rootless user
  # namespaces. It may read consumer-delivered secrets but not direct ones.
  makePodmanProfile = ''
    # podman needs attach_disconnected for rootless user namespaces.
    abi <abi/5.0>,

    include <tunables/global>

    profile podman /nix/store/*/bin/podman flags=(attach_disconnected) {
      all,
      "/run/nscd/socket" rw,
    ${denyReadRules serviceProtectedPaths}
    }
  '';

  # age/ragenix are the only programs allowed to read identity keys.
  # They may decrypt .age files but must not read plaintext home secrets.
  makeIdentityToolProfile = tool: ''
    # ${tool} is the explicit identity-key reader.
    abi <abi/5.0>,

    include <tunables/global>

    profile ${tool} /nix/store/*/bin/${tool} {
      all,
      "/run/nscd/socket" rw,
    ${denyReadRules (lib.unique (homeProtectedPaths ++ systemUserProtectedPaths))}
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
            state = programStates.${name} or "enforce";
            profile = makeProfile name;
          };
        }) programNames
      )
      // lib.optionalAttrs config.virtualisation.podman.enable {
        podman = {
          state = "complain";
          profile = makePodmanProfile;
        };
      }
      // {
        age = {
          state = "complain";
          profile = makeIdentityToolProfile "age";
        };
        ragenix = {
          state = "complain";
          profile = makeIdentityToolProfile "ragenix";
        };
        fallback = {
          state = "complain";
          profile = makeFallbackProfile;
        };
        systemd-user = {
          # Best-effort only: complain keeps the user manager from reading
          # direct secrets, but systemd-run can still select unconfined.
          state = "complain";
          profile = makeSystemdUserProfile;
        };
      };
  };

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
      assertion = !(config.virtualisation.podman.enable && builtins.elem "podman" programNames);
      message = "custom.secrets.access: 'podman' is reserved for the technical podman profile";
    }
    {
      assertion = !(builtins.elem "age" programNames || builtins.elem "ragenix" programNames);
      message = "custom.secrets.access: 'age' and 'ragenix' are reserved for identity-key profiles";
    }
  ];
}
