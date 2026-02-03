{
  lib,
  config,
  myLib,
  ...
}:
{
  options.custom.tune.bpftune.enable = myLib.mkEnabledOption;

  config = lib.mkIf config.custom.tune.bpftune.enable {
    services.bpftune.enable = true;
  };
}
