{
  config,
  inputs,
  lib,
  ...
}:

{
  options = {
    custom.secrets = {
      extraIdentityPaths = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Additional identity paths for age encryption";
      };

      systemAgeKey = {
        enable = lib.mkEnableOption "a system-wide age identity key for secrets not tied to a user";
        path = lib.mkOption {
          type = lib.types.str;
          default = "/etc/age/key.txt";
          description = "Path of the system age identity key";
        };
      };
    };
  };

  config =
    let
      keyCfg = config.custom.secrets.systemAgeKey;
      persistRoot = "/persist";

      identityPath =
        p:
        if !(lib.hasPrefix "/" p) then
          throw "custom.secrets: age identity path '${p}' must be absolute (e.g. \"/etc/age/key.txt\")"
        else if p == "/" || lib.hasSuffix "/" p then
          throw "custom.secrets: age identity path '${p}' must be a file below ${persistRoot}"
        else if lib.hasPrefix "${persistRoot}/" p then
          throw "custom.secrets: age identity path '${p}' must not include ${persistRoot}; it is prepended automatically"
        else
          persistRoot + p;

      identityPaths = map identityPath config.custom.secrets.extraIdentityPaths;

      isPersisted =
        path:
        let
          persistence = config.environment.persistence or { };
          mounts = lib.filter (m: m.enable && (m.persistentStoragePath or persistRoot) == persistRoot) (
            lib.attrValues persistence
          );
          getPath = x: if builtins.isString x then x else (x.file or x.directory);
          persistedFiles = lib.flatten (map (m: map getPath (m.files or [ ])) mounts);
          persistedDirs = lib.flatten (map (m: map getPath (m.directories or [ ])) mounts);

          inFile = lib.elem path persistedFiles;
          inDir = lib.any (dir: dir == path || lib.hasPrefix (dir + "/") path) persistedDirs;
        in
        inFile || inDir;
    in
    {
      environment.systemPackages = [
        inputs.ragenix.packages."${config.nixpkgs.system}".default
      ];

      # Note: Extra identity keys added via custom.secrets.extraIdentityPaths
      # must be persisted in host configuration to avoid infinite recursion.

      assertions =
        map (path: {
          assertion = isPersisted path;
          message = "age identity key '${path}' is not configured in environment.persistence. It must be listed in persistence directories or files.";
        }) config.custom.secrets.extraIdentityPaths
        ++ [
          {
            assertion = builtins.attrNames config.age.secrets == [ ] || identityPaths != [ ];
            message = ''
              custom.secrets: age.secrets are declared, but age.identityPaths is empty.
              Enable custom.secrets.systemAgeKey or add custom.secrets.extraIdentityPaths.
            '';
          }
        ];

      age.identityPaths = identityPaths;

      custom.secrets.extraIdentityPaths = lib.mkIf keyCfg.enable [
        keyCfg.path
      ];
      environment.persistence."/persist".files = lib.mkIf keyCfg.enable [
        keyCfg.path
      ];
    };
}
