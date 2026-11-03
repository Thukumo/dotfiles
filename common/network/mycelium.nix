{
  lib,
  myLib,
  config,
  ...
}:
{
  options.custom.network.mycelium.enable = myLib.mkEnabledOption "mycelium";

  config = lib.mkIf config.custom.network.mycelium.enable {
    services.mycelium = {
      enable = true;
      openFirewall = true;
    };
    # WARP's default ::/3 route covers 400::/7; keep Mycelium out of the tunnel.
    custom.network.cloudflare-warp.excludeRoutes = [ "400::/7" ];
    environment.persistence."/persist".directories = [
      "/var/lib/private/mycelium"
    ];
    environment.shellAliases =
      lib.warnIf (!(builtins.hasAttr config.networking.hostName config.custom.mycelium.hosts))
        "mycelium is enabled on '${config.networking.hostName}' but it is not registered in const/mycelium (custom.mycelium.hosts). Add its IPv6 address for cross-host name resolution."
        {
          my-addr = "sudo mycelium -k /var/lib/mycelium/key.bin inspect";
        };
  };
}
