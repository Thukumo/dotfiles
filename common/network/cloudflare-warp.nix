{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.custom.network.cloudflare-warp = {
    enable = lib.mkEnableOption "Cloudflare Warp";
  };

  config = lib.mkIf config.custom.network.cloudflare-warp.enable {
    nixpkgs.config.allowUnfreePackages = [ pkgs.cloudflare-warp.pname ];
    services.cloudflare-warp.enable = true;
  };
}
