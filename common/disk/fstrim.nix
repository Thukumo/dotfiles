{
  lib,
  config,
  myLib,
  ...
}:
{
  options.custom.disk.fstrim = {
    enable = myLib.mkEnabledOption;
  };
  config = lib.mkIf config.custom.disk.fstrim.enable {
    services.fstrim.enable = true;
  };
}
