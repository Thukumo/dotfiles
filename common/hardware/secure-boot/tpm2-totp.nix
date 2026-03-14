{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.hardware.secure-boot.tpm2-totp;
in
{
  options.custom.hardware.secure-boot.tpm2-totp = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.custom.hardware.secure-boot.enable;
      description = "Enable TPM2 TOTP support";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.tpm2-totp ];

    boot.initrd.systemd = {
      services.tpm2-totp = {
        description = "Calculate and show TPM2 TOTP";
        wantedBy = [ "cryptsetup-pre.target" ];
        before = [ "cryptsetup-pre.target" ];
        after = [ "tpm-devices.target" ];
        conflicts = [ "initrd-switch-root.target" ];
        unitConfig = {
          DefaultDependencies = "no";
          ConditionPathExists = "/dev/tpmrm0";
        };
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.tpm2-totp}/bin/tpm2-totp calculate";
          StandardOutput = "tty";
          StandardError = "tty";
          TTYPath = "/dev/console";
        };
      };
      extraBin.tpm2-totp = "${pkgs.tpm2-totp}/bin/tpm2-totp";
    };
  };
}
