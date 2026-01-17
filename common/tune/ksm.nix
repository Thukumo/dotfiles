{
  config,
  mkEnabledOption,
  ...
}:
{
  options.custom.tune.ksm.enable = mkEnabledOption;

  config = {
    hardware.ksm.enable = config.custom.tune.ksm.enable;
  };
}
