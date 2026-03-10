{
  lib,
  config,
  myLib,
  ...
}:
{
  options.custom.hardware.tune.auto-cpufreq.enable = myLib.mkEnabledOption;

  config = lib.mkIf config.custom.hardware.tune.auto-cpufreq.enable {
    services.auto-cpufreq.enable = true;
    services.thermald.enable = true;
  };
}
