{
  lib,
  config,
  ...
}:
{
  options.custom.hardware.tune.earlyoom.enable = lib.mkEnableOption "earlyoom";

  config = lib.mkIf config.custom.hardware.tune.earlyoom.enable {
    services.earlyoom.enable = true;
  };
}
