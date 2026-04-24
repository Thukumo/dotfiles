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
  options.custom.hardware.secure-boot = {
    enable = lib.mkEnableOption "Secure Boot with Lanzaboote";
    init = lib.mkEnableOption "use when init secure boot";
  };

  config = lib.mkIf cfg.enable {
    boot.loader.systemd-boot.enable = lib.mkForce false;

    boot.lanzaboote = {
      enable = !cfg.init;
      pkiBundle = "/var/lib/sbctl";
    };

    environment.systemPackages = [ pkgs.sbctl ];

    environment.persistence."/persist".directories = [
      "/var/lib/sbctl"
    ];
  };
}
