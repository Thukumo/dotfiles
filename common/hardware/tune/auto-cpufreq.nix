{
  lib,
  config,
  myLib,
  ...
}:
{
  options.custom.hardware.tune.auto-cpufreq.enable = myLib.mkEnabledOption "auto-cpufreq";

  config = lib.mkIf config.custom.hardware.tune.auto-cpufreq.enable {
    # auto-cpufreq 3.1.0 writes EPP after setting the governor. intel_pstate
    # rejects EPP changes while the performance policy is active (EBUSY), so
    # use powersave here; it still boosts via HWP. Do not run thermald
    # alongside auto-cpufreq; both write cpufreq sysfs.
    services.auto-cpufreq = {
      enable = true;
      settings = {
        charger = {
          governor = "powersave";
          energy_performance_preference = "balance_performance";
          turbo = "auto";
        };
        battery = {
          governor = "powersave";
          energy_performance_preference = "power";
          turbo = "auto";
        };
      };
    };
  };
}
