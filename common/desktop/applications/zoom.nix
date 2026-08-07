{
  lib,
  config,
  desktopLib,
  myLib,
  pkgs,
  ...
}:

{
  config = lib.mkIf (myLib.anyUser config (user: user.desktop.apps.zoom.enable)) {
    nixpkgs.config.allowUnfreePackages = [ pkgs.zoom-us.pname ];
    home-manager.users = desktopLib.mkHome (user: user.custom.desktop.apps.zoom.enable) (
      _:
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          zoom-us
        ];
        home.persistence."/persist" = {
          directories = [
            ".zoom"
            ".cache/zoom"
          ];
          files = [
            ".config/zoom.conf"
            ".config/zoomus.conf"
          ];
        };
      }
    );
  };
}
