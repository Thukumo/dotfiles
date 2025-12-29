{
  lib,
  config,
  mkEnabledOption,
  ...
}:
{
  options.custom.tune.auto-cpufreq.enable = mkEnabledOption;

  config = lib.mkIf config.custom.tune.auto-cpufreq.enable {
    services.auto-cpufreq.enable = true;
    services.thermald.enable = true;
  };
}
