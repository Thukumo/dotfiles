{
  lib,
  config,
  myLib,
  pkgs,
  ...
}:
{
  options.custom.hardware.tune.ananicy.enable = myLib.mkEnabledOption;

  config = lib.mkIf config.custom.hardware.tune.ananicy.enable {
    services.ananicy = {
      enable = true;
      package = pkgs.ananicy-cpp;
      rulesProvider = pkgs.ananicy-cpp;
    };
  };
}
