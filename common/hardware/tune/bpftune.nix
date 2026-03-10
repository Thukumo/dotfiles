{
  lib,
  config,
  myLib,
  ...
}:
{
  options.custom.hardware.tune.bpftune.enable = myLib.mkEnabledOption;

  config = lib.mkIf config.custom.hardware.tune.bpftune.enable {
    services.bpftune.enable = true;
  };
}
