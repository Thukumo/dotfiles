{
  lib,
  desktopLib,
  ...
}:

{
  config.home-manager.users = desktopLib.mkHome (_user: true) (
    user:
    { pkgs, ... }:

    {
      home.packages = lib.mkMerge [
        (lib.mkIf user.custom.desktop.apps.libreoffice.enable [ pkgs.libreoffice-still ])
        (lib.mkIf user.custom.desktop.apps.gnome-disk-utility.enable [ pkgs.gnome-disk-utility ])
        (lib.mkIf user.custom.desktop.apps.thunar.enable [ pkgs.thunar ])
      ];
    }
  );
}
