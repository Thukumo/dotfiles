{
  lib,
  config,
  myLib,
  ...
}:
{
  options.custom.hardware.disk.fstrim = {
    enable = myLib.mkEnabledOption "fstrim";
  };
  config = lib.mkIf config.custom.hardware.disk.fstrim.enable {
    services.fstrim.enable = true;
  };
}
