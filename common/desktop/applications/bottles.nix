{
  config,
  lib,
  desktopLib,
  myLib,
  pkgs,
  ...
}:
{
  config = lib.mkIf (myLib.anyUser config (user: user.desktop.apps.bottles.enable)) {
    nixpkgs.config.allowUnfreePackages = [ pkgs.lsfg-vk.pname ];
    home-manager.users = desktopLib.mkHome (user: user.custom.desktop.apps.bottles.enable) (
      _:
      { pkgs, ... }:
      {
        home.packages = [ (pkgs.bottles.override { removeWarningPopup = true; }) ];
        home.persistence."/persist".directories = [
          ".local/share/bottles"
        ];
      }
    );
  };
}
