{
  lib,
  mkForEachUsers,
  pkgs,
  ...
}:
{
  options.users.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        {
          options.custom.desktop.apps.google-chrome.enable = lib.mkEnableOption "Google Chrome";
        }
      )
    );
  };

  config = {
    home-manager.users = mkForEachUsers (user: user.custom.desktop.apps.google-chrome.enable) (
      user:
      { config, ... }:
      {
        home.packages = [ pkgs.google-chrome ];
        home.persistence."/persist${config.home.homeDirectory}".directories = [
          ".config/google-chrome"
        ];
      }
    );
  };
}
