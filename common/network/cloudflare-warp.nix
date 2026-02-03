{
  lib,
  config,
  myLib,
  ...
}:
{
  options.custom.network.cloudflare-warp = {
    enable = myLib.mkEnabledOption;
  };

  config = lib.mkIf config.custom.network.cloudflare-warp.enable {
    services.cloudflare-warp.enable = true;
  };
}
