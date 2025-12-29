{ lib, config, ... }:

{
  options.custom.laptop.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
  };
  config = lib.mkIf config.custom.laptop.enable {
    services.tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "balance_performance";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_performance";
      };
    };
  };
}
