{ config, ... }:

{
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

    # cloudflared connects to nginx over loopback, so the original client
    # address is only available in the header Cloudflare adds to tunneled
    # requests.
    commonHttpConfig = ''
      set_real_ip_from 127.0.0.1;
      set_real_ip_from ::1;
      real_ip_header CF-Connecting-IP;

      # Shibaura Institute of Technology (SITNET-AS, AS55910)
      # https://stat.ripe.net/AS55910
      geo $from_shibaura {
        default 0;
        202.18.64.0/18 1;
        2001:df3:4c0::/48 1;
      }

      # Keep rickrolling a client that has already been caught once, even
      # after it leaves the university network.
      map "$from_shibaura:$cookie_sit_rickroll" $sit_rickroll {
        default 0;
        ~^1 1;
        ~:1$ 1;
      }
    '';

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
        "blog.tsukumo.f5.si" = {
          listen = tunnelListener;
          locations."/" = {
            extraConfig = ''
              if ($sit_rickroll) {
                add_header Set-Cookie "sit_rickroll=1; Path=/; Max-Age=31536000; Secure; HttpOnly; SameSite=Lax" always;
                add_header Cache-Control "no-store" always;
                return 302 https://www.youtube.com/watch?v=dQw4w9WgXcQ;
              }
              return 404;
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
