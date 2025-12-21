{ lib, config, mkForEachUsers, pkgs, ... }:
{
  options.users.users = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options.custom.desktop.apps.discord = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
      };
    });
  };

  config = {
    home-manager.users = mkForEachUsers (user: user.custom.desktop.apps.discord.enable) (user: { config, ... }: {
      home.packages = [ pkgs.discord ];
      home.persistence."/persist${config.home.homeDirectory}".directories = [
        ".config/discord"
      ];
    });
  };
}
