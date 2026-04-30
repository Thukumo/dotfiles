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
    # https://github.com/NixOS/nixpkgs/pull/515001
    boot.kernel.sysctl."net.ipv4.conf.all.src_valid_mark" = 1;
  };
}
