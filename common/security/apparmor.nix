{
  config,
  lib,
  ...
}:
let
  access = config.custom.secrets.access;

  # Only system secrets get AppArmor profiles. Home secrets are decrypted and
  # owned by the user; hiding them from the user's own processes is not a
  # boundary AppArmor can provide, so they are deliberately user-level.
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
      programs = if a == null then [ ] else a.programs;
      allowed =
        if kind == "credential" then
          credentialDirs
        else
          lib.unique ([ secret.path ] ++ lib.optional (generation != null) generation);
      protected = a == null || (a.acceptedRisk or null) == null;
    }
  ) config.age.secrets;

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

  protectedPaths = lib.unique (
    lib.concatMap (entry: if entry.protected then entry.paths else [ ]) systemEntries
    ++ systemIdentityPaths
  );

  programNames = lib.unique (lib.concatMap (entry: entry.programs) systemEntries);

  allowedPaths =
    program:
    lib.unique (
      lib.concatMap (
        entry: if entry.protected && builtins.elem program entry.programs then entry.allowed else [ ]
      ) systemEntries
    );

  deniedPaths =
    program: lib.filter (path: !(builtins.elem path (allowedPaths program))) protectedPaths;

  # Dedicated service daemons only. `all` keeps the daemon working; the deny
  # rules remove access to system secrets that do not belong to it.
  makeProfile =
    name:
    let
      denyRules = lib.concatMapStringsSep "\n" (
        path: "  deny \"${path}\" rwklmx,\n  deny \"${path}\" a,"
      ) (deniedPaths name);
    in
    ''
      # Dedicated service daemon profile generated from custom.secrets.access.
      abi <abi/5.0>,

      include <tunables/global>

      profile ${name} /nix/store/*/bin/${name} flags=(attach_disconnected) {
        all,
        "/run/nscd/socket" rw,
      ${denyRules}
      }
    '';

  allPolicyPaths = lib.unique (
    lib.concatMap (entry: entry.paths) systemEntries ++ systemIdentityPaths
  );
  invalidAppArmorPaths = lib.filter (
    path:
    lib.any (bad: lib.hasInfix bad (toString path)) [
      "\""
      "\\"
      "\n"
      "\r"
      "{"
      "}"
    ]
  ) allPolicyPaths;

  invalidProgramNames = lib.filter (
    name: builtins.match "[A-Za-z0-9][A-Za-z0-9._+-]*" name == null
  ) programNames;
in
{
  security.apparmor = {
    enable = true;
    killUnconfinedConfinables = false;
    policies = lib.listToAttrs (
      map (name: {
        inherit name;
        value = {
          state = "enforce";
          profile = makeProfile name;
        };
      }) programNames
    );
  };

  assertions = [
    {
      assertion = invalidProgramNames == [ ];
      message = "custom.secrets.access: program names must be executable basenames matching [A-Za-z0-9][A-Za-z0-9._+-]*: ${lib.concatStringsSep ", " invalidProgramNames}";
    }
    {
      assertion = invalidAppArmorPaths == [ ];
      message = "custom.secrets.access: AppArmor paths must not contain quotes, backslashes, newlines, or braces: ${lib.concatStringsSep ", " (map toString invalidAppArmorPaths)}";
    }
  ];
}
