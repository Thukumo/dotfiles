{
  lib,
  mkForEachUsers,
  ...
}:

{
  options.users.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (_: {
        options.custom.desktop.apps = {
          libreoffice.enable = lib.mkEnableOption "LibreOffice";
          gnome-disk-utility.enable = lib.mkEnableOption "GNOME Disk Utility";
          thunar.enable = lib.mkEnableOption "Thunar";
        };
      })
    );
  };

  config.home-manager.users = mkForEachUsers (user: true) (
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
