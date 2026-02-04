{
  config,
  inputs,
  lib,
  myLib,
  ...
}:

{
  options = {
    custom.users = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options.secrets.secretKey = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Path to user's secret key for age encryption (relative to /persist)";
          };
        }
      );
    };

    custom.secrets = {
      extraIdentityPaths = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Additional identity paths for age encryption";
      };
    };
  };

  config =
    let
      userRekeyAliases = lib.mkMerge (
        lib.mapAttrsToList (
          name: userConfig:
          lib.optionalAttrs (userConfig.secrets.secretKey or null != null) {
            "rekey-${name}" = "pushd ${
              config.users.users.${name}.home
            }/dotfiles/ && sudo ragenix -r -i /persist${userConfig.secrets.secretKey} && popd";
          }
        ) config.custom.users
      );

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

      # Note: Secret key directories must be added to environment.persistence
      # in each host configuration to avoid infinite recursion

      assertions = map (path: {
        assertion = isPersisted path;
        message = "age identity key '${path}' is not configured in environment.persistence. It must be listed in persistence directories or files.";
      }) config.custom.secrets.extraIdentityPaths;

      age = {
        identityPaths = map (p: "/persist" + p) config.custom.secrets.extraIdentityPaths;
        secrets = {
          "passwd_tsukumo".file = ./secrets/passwd_tsukumo.age;
          "home-manager_key" = {
            file = ./secrets/home_manager_key.age;
            owner = "tsukumo";
            mode = "400";
          };
        };
      };

      home-manager.users = myLib.mkForEachUsers (u: u.name == "tsukumo") (u: {
        imports = [
          ./home-ragenix
        ];
      });

      environment.shellAliases = userRekeyAliases;
    };
}
