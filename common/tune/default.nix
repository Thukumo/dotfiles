{ lib, config, mkEnabledOption, pkgs, ... }:

let
  tune = config.custom.tune;
in
{

  options.custom.tune = {
    auto-cpufreq.enable = mkEnabledOption;
    bpftune.enable = mkEnabledOption;
    ananicy.enable = mkEnabledOption;
  };
  config = lib.mkMerge [
    (lib.mkIf tune.auto-cpufreq.enable {
      services.auto-cpufreq.enable = true;
      services.thermald.enable = true;
    })
    (lib.mkIf tune.bpftune.enable { services.bpftune.enable = true; })
    (lib.mkIf tune.ananicy.enable {
      services.ananicy = {
        enable = true;
        package = pkgs.ananicy-cpp;
        rulesProvider = pkgs.ananicy-cpp;
      };
    })
  ];
}
