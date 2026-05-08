{
  lib,
  config,
  myLib,
  ...
}:
{
  options.custom.hardware.tune.earlyoom.enable = myLib.mkEnabledOption;

  config = lib.mkIf config.custom.hardware.tune.earlyoom.enable {
    services.earlyoom.enable = true;
  };
}
