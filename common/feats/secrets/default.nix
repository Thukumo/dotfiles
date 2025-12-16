{ config, inputs, lib, ... }:

{
  options.custom.secrets.secretKey = lib.mkOption {
    type = lib.types.str;
  };
  config = {
    environment.systemPackages = [
      inputs.ragenix.packages."${config.nixpkgs.system}".default
    ];
    environment.persistence."/persist".directories = [
      (builtins.dirOf config.custom.secrets.secretKey)
    ];

    age = {
      identityPaths = [ ("/persist" + config.custom.secrets.secretKey) ];
      secrets = {
        "passwd_tsukumo".file = ./secrets/passwd_tsukumo.age;
        "home-manager_key" = {
          file = ./secrets/home_manager_key.age;
          owner = config.users.users."tsukumo".name;
          mode = "400";
        };
      };
    };
    home-manager.users."tsukumo".imports = [
      ./home-ragenix
    ];
    environment.shellAliases = {
      rekey = "pushd ${config.users.users."tsukumo".home}/dotfiles/ && sudo ragenix -r -i ${config.custom.secrets.secretKey} && cd -";
    };
  };
}
