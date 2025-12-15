{ config, inputs, lib, ... }:

{
  options.custom.secrets.secretKey = lib.mkOption {
    type = lib.types.str;
  };
  config = {
    environment.systemPackages = [
      inputs.ragenix.packages."${config.nixpkgs.system}".default
    ];

    age = {
      identityPaths = [ config.custom.secrets.secretKey ];
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
  };
}
