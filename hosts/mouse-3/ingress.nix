{ config, ... }:

{
  age.secrets."cloudflared_nowplaying".file = ./secrets/cloudflared-nowplaying-credentials.age;
  services.cloudflared = {
    enable = true;
    tunnels.mouse-3 = {
      credentialsFile = config.age.secrets.cloudflared_nowplaying.path;
      default = "http_status:404";
      # https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/troubleshoot-tunnels/common-errors/#my-tunnel-randomly-disconnects
      protocol = "http2";
      ingress."*.tsukumo.f5.si".service = "http://127.0.0.1:8182";
    };
  };

  services.nginx = {
    enable = true;
    virtualHosts =
      let
        tunnelListener = [
          {
            addr = "127.0.0.1";
            port = 8182;
          }
        ];
      in
      {
        "api-nowplaying.tsukumo.f5.si" = {
          listen = tunnelListener;
          locations."/" = {
            proxyPass = "http://127.0.0.1:8181";
          };
        };
        "nowplaying.tsukumo.f5.si" = {
          listen = tunnelListener;
          locations."/" = {
            proxyPass = "http://127.0.0.1:8183";
          };
        };
        "mouse-3-opencode.tsukumo.f5.si" = {
          listen = tunnelListener;
          locations."/" = {
            proxyPass = "http://127.0.0.1:4096";
            proxyWebsockets = true;
            extraConfig = ''
              proxy_buffering off;
              proxy_read_timeout 3600s;
            '';
          };
        };
        "mouse-3-metrics.tsukumo.f5.si" = {
          listen = tunnelListener;
          locations."/" = {
            proxyPass = "http://127.0.0.1:61208";
            proxyWebsockets = true;
            extraConfig = ''
              proxy_buffering off;
              proxy_read_timeout 3600s;
            '';
          };
        };
        "_" = {
          listen = tunnelListener;
          default = true;
          locations."/" = {
            return = "404";
          };
        };
      };
  };
}
