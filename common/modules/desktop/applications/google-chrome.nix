{ lib, config, ... }:
{
  options.custom.desktop.apps.google-chrome = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.custom.desktop.type != null;
    };
  };
  config = lib.mkIf config.custom.desktop.apps.google-chrome.enable {
    home-manager.users."tsukumo" =
      { pkgs, config, ... }:
      {
        home.packages = [ pkgs.google-chrome ];
        home.persistence."/persist/${config.home.homeDirectory}".directories = [
          ".config/google-chrome"
        ];
      };
  };
}
