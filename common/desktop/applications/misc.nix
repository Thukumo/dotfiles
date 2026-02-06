{
  lib,
  myLib,
  ...
}:

{
  options.custom.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.desktop.apps = {
          libreoffice.enable = lib.mkEnableOption "LibreOffice";
          gnome-disk-utility.enable = lib.mkEnableOption "GNOME Disk Utility";
          thunar.enable = lib.mkEnableOption "Thunar";
        };
      }
    );
  };

  config.home-manager.users = myLib.mkForEachUsers (user: true) (
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
