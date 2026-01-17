{
  lib,
  mkEnabledOption,
  config,
  ...
}:
{
  options.custom.network.mycelium.enable = mkEnabledOption;

  config = lib.mkIf config.custom.network.mycelium.enable {
    services.mycelium = {
      enable = true;
      openFirewall = true;
    };
  };
}
