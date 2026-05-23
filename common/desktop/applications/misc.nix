{
  lib,
  desktopLib,
  ...
}:

{
  config.home-manager.users = desktopLib.mkHome (_user: true) (
    _:
    { pkgs, myConfig, ... }:

    {
      home.packages = lib.mkMerge [
        (lib.mkIf (myConfig.desktop.apps.libreoffice.enable or false) [ pkgs.libreoffice-still ])
        (lib.mkIf (myConfig.desktop.apps.gnome-disk-utility.enable or false) [ pkgs.gnome-disk-utility ])
        (lib.mkIf (myConfig.desktop.apps.thunar.enable or false) [ pkgs.thunar ])
      ];
    }
  );
}
