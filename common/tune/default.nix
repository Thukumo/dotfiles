{ lib, config, mkEnabledOption, ... }:

let
  tune = config.custom.tune;
in
{

  options.custom.tune = {
    auto-cpufreq.enable = mkEnabledOption;
    bpftune.enable = mkEnabledOption;
  };
  config = lib.mkMerge [
    (lib.mkIf tune.auto-cpufreq.enable {
      services.auto-cpufreq.enable = true;
      services.thermald.enable = true;
    })
    (lib.mkIf tune.bpftune.enable { services.bpftune.enable = true; })
  ];
}
