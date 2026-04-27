{
  lib,
  config,
  ...
}:
{
  options.custom.network.cloudflare-warp = {
    enable = lib.mkEnableOption "Cloudflare Warp";
  };

  config = lib.mkIf config.custom.network.cloudflare-warp.enable {
    services.cloudflare-warp.enable = true;
    networking.firewall.checkReversePath = "loose";
  };
}
