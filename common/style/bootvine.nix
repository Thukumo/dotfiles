{
  config,
  lib,
  inputs,
  ...
}:
let
  myConfig = config.custom.style.bootvine;
in
{
  imports = [ inputs.bootvine.nixosModules.default ];

  options.custom.style.bootvine = {
    startAfterUnlock = lib.mkOption {
      type = lib.types.bool;
      default = config.custom.hardware.secure-boot.tpm2-totp.enable;
      description = ''
        Start bootvine in the initrd only after cryptsetup.target, so the
        TPM2 TOTP and LUKS prompt stay on the normal console. Defaults to on
        when TPM2 TOTP is enabled.
      '';
    };
  };

  config = lib.mkIf (config.custom.style.bootScreen == "bootvine") {
    services.bootvine.enable = true;

    boot.initrd.systemd.services.bootvine.after = lib.optionals myConfig.startAfterUnlock [
      "cryptsetup.target"
    ];
  };
}
