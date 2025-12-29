{
  lib,
  config,
  mkEnabledOption,
  ...
}:
{
  options.custom.network.cloudflare-warp = {
    enable = mkEnabledOption;
  };

  config = lib.mkIf config.custom.network.cloudflare-warp.enable {
    services.cloudflare-warp.enable = true;
  };
}
