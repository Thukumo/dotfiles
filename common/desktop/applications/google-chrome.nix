{
  lib,
  config,
  desktopLib,
  myLib,
  pkgs,
  ...
}:
{
  config = lib.mkIf (myLib.anyUser config (user: user.desktop.apps.google-chrome.enable)) {
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
