{
  config,
  inputs,
  lib,
  mkForEachUsers,
  ...
}:

{
  options = {
    users.users = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options.custom.secrets.secretKey = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Path to user's secret key for age encryption (relative to /persist)";
        };
      });
    };
    
    custom.secrets = {
      extraIdentityPaths = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Additional identity paths for age encryption";
      };
    };
  };

  config = let
    userIdentityPaths = lib.flatten (
      lib.mapAttrsToList (_: u:
        lib.optional (u.custom.secrets.secretKey or null != null)
          ("/persist" + u.custom.secrets.secretKey)
      ) config.users.users
    );
    
    userRekeyAliases = lib.mkMerge (
      lib.mapAttrsToList (name: u:
        lib.optionalAttrs (u.custom.secrets.secretKey or null != null) {
          "rekey-${name}" = "pushd ${u.home}/dotfiles/ && sudo ragenix -r -i /persist${u.custom.secrets.secretKey} && popd";
        }
      ) config.users.users
    );
  in {
    environment.systemPackages = [
      inputs.ragenix.packages."${config.nixpkgs.system}".default
    ];

    # Note: Secret key directories must be added to environment.persistence
    # in each host configuration to avoid infinite recursion

    age = {
      identityPaths = userIdentityPaths ++ config.custom.secrets.extraIdentityPaths;
      secrets = {
        "passwd_tsukumo".file = ./secrets/passwd_tsukumo.age;
        "home-manager_key" = {
          file = ./secrets/home_manager_key.age;
          owner = "tsukumo";
          mode = "400";
        };
      };
    };

    home-manager.users = mkForEachUsers (u: u.name == "tsukumo") (u: {
      imports = [
        ./home-ragenix
      ];
    });

    environment.shellAliases = userRekeyAliases;
  };
}
