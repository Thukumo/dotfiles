{
  config,
  lib,
  pkgs,
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
            libreoffice.enable = lib.mkOption {
              type = lib.types.bool;
              default = config.custom.desktop.type != null;
            };
            zoom.enable = lib.mkOption {
              type = lib.types.bool;
              default = config.custom.desktop.type != null;
            };
            gnome-disk-utility.enable = lib.mkOption {
              type = lib.types.bool;
              default = config.custom.desktop.type != null;
            };
            rquickshare.enable = lib.mkOption {
              type = lib.types.bool;
              default = config.custom.desktop.type != null;
            };
            thunar.enable = lib.mkOption {
              type = lib.types.bool;
              default = config.custom.desktop.type != null;
            };
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
          (lib.mkIf user.custom.desktop.apps.thunar.enable [ pkgs.xfce.thunar ])
        ];
      });
    }
    {
      # enable mDNS
      services.avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
      };
    }
  ];
}
