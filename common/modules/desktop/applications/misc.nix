{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.desktop.apps;
in
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
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.libreoffice.enable {
      home-manager.users."tsukumo".home.packages = with pkgs; [
        libreoffice-still
      ];
    })
    (lib.mkIf cfg.zoom.enable {
      home-manager.users."tsukumo".home.packages = with pkgs; [
        zoom-us
      ];
    })
    (lib.mkIf cfg.gnome-disk-utility.enable {
      home-manager.users."tsukumo".home.packages = with pkgs; [
        gnome-disk-utility
      ];
    })
    (lib.mkIf cfg.rquickshare.enable {
      home-manager.users."tsukumo".home.packages = with pkgs; [
        rquickshare
      ];
      # enable mDNS
      services.avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
      };
    })
  ];
}
