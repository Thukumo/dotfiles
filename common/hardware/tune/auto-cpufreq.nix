{
  lib,
  config,
  myLib,
  pkgs,
  ...
}:
{
  options.custom.hardware.tune.auto-cpufreq.enable = myLib.mkEnabledOption "auto-cpufreq";

  config = lib.mkIf config.custom.hardware.tune.auto-cpufreq.enable {
    services.auto-cpufreq.enable = true;
    services.thermald.enable = true;
    systemd.services.thermald.serviceConfig.ExecStart =
      lib.mkForce "${pkgs.thermald}/sbin/thermald --no-daemon --dbus-enable --ignore-cpuid-check";
  };
}
