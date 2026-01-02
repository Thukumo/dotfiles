{
  lib,
  pkgs,
  config,
  mkForEachUsers,
  ...
}:

{
  options.users.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        {
          options.custom.desktop.apps = {
            libreoffice.enable = lib.mkEnableOption "LibreOffice";
            zoom.enable = lib.mkEnableOption "Zoom";
            gnome-disk-utility.enable = lib.mkEnableOption "GNOME Disk Utility";
            rquickshare.enable = lib.mkEnableOption "RQuickShare";
            thunar.enable = lib.mkEnableOption "Thunar";
          };
        }
      )
    );
  };

  config = lib.mkMerge [
    {
      home-manager.users = mkForEachUsers (user: true) (user: {
        home.packages = lib.mkMerge [
          (lib.mkIf user.custom.desktop.apps.libreoffice.enable [ pkgs.libreoffice-still ])
          (lib.mkIf user.custom.desktop.apps.zoom.enable [ pkgs.zoom-us ])
          (lib.mkIf user.custom.desktop.apps.gnome-disk-utility.enable [ pkgs.gnome-disk-utility ])
          (lib.mkIf user.custom.desktop.apps.rquickshare.enable [ pkgs.rquickshare ])
          (lib.mkIf user.custom.desktop.apps.thunar.enable [ pkgs.thunar ])
        ];
      });
    }
    {
      # enable mDNS (required for rquickshare)
      services.avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
      };
    }
  ];
}
