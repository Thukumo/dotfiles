{
  lib,
  config,
  myLib,
  ...
}:
{
  options.custom.hardware.tune.earlyoom.enable = myLib.mkEnabledOption "earlyoom";

  config = lib.mkIf config.custom.hardware.tune.earlyoom.enable {
    services.earlyoom.enable = true;
  };
}
