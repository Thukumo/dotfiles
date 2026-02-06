{
  config,
  myLib,
  lib,
  ...
}:
{
  options.custom.tune.ksm = {
    enable = myLib.mkEnabledOption;
    enableForAll = lib.mkEnableOption "Enable ksm for all";
  };

  config = lib.mkIf config.custom.tune.ksm.enable {
    hardware.ksm.enable = true;
    # https://github.com/cachyos/cachyos-pkgbuilds/tree/master/cachyos-ksm-settings
    environment.etc."systemd/system/service.d/10-ksm.conf" =
      lib.mkIf config.custom.tune.ksm.enableForAll {
        text = ''
          [Service]
          MemoryKSM=yes
        '';
      };
  };
}
