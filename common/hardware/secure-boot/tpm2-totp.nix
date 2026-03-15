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
        wantedBy = [ "cryptsetup.target" ];
        before = [ "cryptsetup-pre.target" ];
        wants = [ "cryptsetup-pre.target" ];
        after = [ "tpm2.target" ];
        conflicts = [ "initrd-switch-root.target" ];
        unitConfig = {
          DefaultDependencies = "no";
          ConditionPathExists = "/dev/tpm0";
        };
        serviceConfig = {
          Type = "oneshot";
          StandardOutput = "tty";
          StandardError = "tty";
          TTYPath = "/dev/console";
        };
        script = ''
          totp=$(${pkgs.tpm2-totp}/bin/tpm2-totp calculate 2>&1) || totp="CALCULATION FAILED"

          # Single echo call for the entire box to minimize chance of interleaved logs
          echo -e "\n\n\033[1;32m#################################################\n#                                               #\n#              TPM2 TOTP CALCULATE              #\n#                                               #\n#                    $totp                     #\n#                                               #\n#################################################\033[0m\n\n"
        '';
      };
      extraBin.tpm2-totp = "${pkgs.tpm2-totp}/bin/tpm2-totp";
    };
  };
}
