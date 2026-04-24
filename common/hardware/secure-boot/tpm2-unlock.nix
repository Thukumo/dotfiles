{
  config,
  lib,
  ...
}:
let
  cfg = config.custom.hardware.secure-boot.tpm2-unlock;
  parentCfg = config.custom.hardware.secure-boot;
in
{
  options.custom.hardware.secure-boot.tpm2-unlock = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = parentCfg.enable;
      description = "Enable TPM2 LUKS unlocking";
    };
    luksDevice = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default =
        if config.custom.hardware.disk.disko.enable then
          config.custom.hardware.disk.disko.luksDeviceName
        else
          null;
      description = "The name of the LUKS device to apply TPM2 unlock settings to";
    };
  };

  config = lib.mkIf (cfg.enable && cfg.luksDevice != null) {
    boot.initrd.luks.devices."${cfg.luksDevice}".crypttabExtraOpts = [
      "tpm2-device=auto"
      "tpm2-pcrs=0+2+7"
      "tpm2-pin=yes"
    ];
  };
}
