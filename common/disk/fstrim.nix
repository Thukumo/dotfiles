{ lib, config, mkEnabledOption, ... }:
{
  options.custom.disk.fstrim = {
    enable = mkEnabledOption;
  };
  config = lib.mkIf config.custom.disk.fstrim.enable {
    services.fstrim.enable = true;
  };
}
