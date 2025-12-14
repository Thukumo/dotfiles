{ lib, config, ... }:
{
  options.custom.apps.discord = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.custom.desktop.type != null;
    };
  };
  config = lib.mkIf config.custom.apps.discord.enable {
    home-manager.users."tsukumo" =
      { pkgs, config, ... }:
      {
        home.packages = [ pkgs.discord ];
        home.persistence."/persist/${config.home.homeDirectory}".directories = [
          ".config/discord"
        ];
      };
  };
}
