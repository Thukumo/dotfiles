{ lib, config, ... }:

{
  options.custom.laptop.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
  };
  config = lib.mkIf config.custom.laptop.enable {
    services.auto-cpufreq.enable = true;
  };
}
