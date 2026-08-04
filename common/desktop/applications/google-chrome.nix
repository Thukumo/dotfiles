{
  lib,
  config,
  desktopLib,
  pkgs,
  ...
}:
{
  config =
    lib.mkIf
      (builtins.any (user: user.desktop.apps.google-chrome.enable) (
        builtins.attrValues config.custom.users
      ))
      {
        nixpkgs.config.allowUnfreePackages = [ pkgs.google-chrome.pname ];
        home-manager.users = desktopLib.mkHome (user: user.custom.desktop.apps.google-chrome.enable) (
          _:
          { pkgs, ... }:
          {
            home.packages = [ pkgs.google-chrome ];
            home.persistence."/persist".directories = [
              ".config/google-chrome"
            ];
          }
        );
      };
}
