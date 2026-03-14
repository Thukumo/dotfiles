{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.hardware.secure-boot;
in
{
  config = lib.mkIf cfg.enable {
    boot.loader.systemd-boot.enable = lib.mkForce false;

    boot.lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };

    environment.systemPackages = [ pkgs.sbctl ];

    environment.persistence."/persist".directories = [
      "/var/lib/sbctl"
    ];
  };
}
