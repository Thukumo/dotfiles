{
  lib,
  config,
  ...
}:
{
  options.custom.network.wait-online.enable = lib.mkEnableOption "NetworkManager-wait-online";

  config.systemd.services.NetworkManager-wait-online.enable =
    config.custom.network.wait-online.enable;
}
