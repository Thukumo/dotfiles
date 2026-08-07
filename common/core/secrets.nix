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

      isPersisted =
        path:
        let
          persistence = config.environment.persistence or { };
          mounts = lib.attrValues persistence;
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

      assertions = map (path: {
        assertion = isPersisted path;
        message = "age identity key '${path}' is not configured in environment.persistence. It must be listed in persistence directories or files.";
      }) config.custom.secrets.extraIdentityPaths;

      age.identityPaths = map (p: "/persist" + p) config.custom.secrets.extraIdentityPaths;

      custom.secrets.extraIdentityPaths = lib.mkIf keyCfg.enable [
        keyCfg.path
      ];
      environment.persistence."/persist".files = lib.mkIf keyCfg.enable [
        keyCfg.path
      ];
    };
}
