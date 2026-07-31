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
      (builtins.any (user: user.desktop.apps.zoom.enable or false) (
        builtins.attrValues config.custom.users
      ))
      {
        nixpkgs.config.allowUnfreePackages = [ pkgs.zoom-us.pname ];
        home-manager.users = desktopLib.mkHome (user: user.custom.desktop.apps.zoom.enable or false) (
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
