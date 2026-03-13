{
  lib,
  config,
  myLib,
  ...
}:
{
  options.custom.hardware.tune.powertop.enable = myLib.mkEnabledOption;

  config = lib.mkIf config.custom.hardware.tune.powertop.enable {
    powerManagement.powertop.enable = true;
  };
}
