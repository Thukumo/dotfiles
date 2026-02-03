{
  config,
  myLib,
  ...
}:
{
  options.custom.tune.ksm.enable = myLib.mkEnabledOption;

  config = {
    hardware.ksm.enable = config.custom.tune.ksm.enable;
  };
}
