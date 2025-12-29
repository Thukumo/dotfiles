{
  lib,
  config,
  mkEnabledOption,
  ...
}:
{
  options.custom.tune.bpftune.enable = mkEnabledOption;

  config = lib.mkIf config.custom.tune.bpftune.enable {
    services.bpftune.enable = true;
  };
}
