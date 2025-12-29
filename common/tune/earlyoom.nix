{
  lib,
  config,
  ...
}:
{
  options.custom.tune.earlyoom.enable = lib.mkEnableOption "earlyoom";

  config = lib.mkIf config.custom.tune.earlyoom.enable {
    services.earlyoom.enable = true;
  };
}
