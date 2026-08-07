{
  lib,
  config,
  myLib,
  ...
}:
{
  options.custom.hardware.tune.bpftune.enable = myLib.mkEnabledOption "bpftune";

  config = lib.mkIf config.custom.hardware.tune.bpftune.enable {
    services.bpftune.enable = true;
  };
}
