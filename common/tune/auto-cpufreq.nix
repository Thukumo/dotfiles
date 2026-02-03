{
  lib,
  config,
  myLib,
  ...
}:
{
  options.custom.tune.auto-cpufreq.enable = myLib.mkEnabledOption;

  config = lib.mkIf config.custom.tune.auto-cpufreq.enable {
    services.auto-cpufreq.enable = true;
    services.thermald.enable = true;
  };
}
