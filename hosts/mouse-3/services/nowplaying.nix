{ inputs, pkgs, ... }:

{
  home-manager.users."tsukumo" = {
    home.persistence."/persist".directories = [ ".local/share/nowplaying" ];

    age.secrets."nowplaying_token".file =
      ../../../common/desktop/services/nowplaying/nowplaying-token.age;

    services.podman.containers = {
      nowplaying = {
        image = "docker-archive:${inputs.nowplaying.packages.x86_64-linux.image}";
        network = "host";
        environment = {
          NOWPLAYING_BIND = "127.0.0.1:8181";
          NOWPLAYING_DATA = "/data/listens.jsonl";
        };
        volumes = [ "/persist/home/tsukumo/.local/share/nowplaying:/data" ];
        # agenix default secret location, %t expands to $XDG_RUNTIME_DIR
        environmentFile = [ "%t/agenix/nowplaying_token" ];
      };

      dashboard = {
        image = "docker-archive:${inputs.nowplaying.packages.x86_64-linux.image-dashboard}";
        network = "host";
        environment = {
          HOST = "127.0.0.1";
          PORT = "8183";
          NOWPLAYING_API = "http://127.0.0.1:8181";
        };
      };
    };

    systemd.user.services.cloudflared-watch = {
      Unit.Description = "Watch nowplaying reachability through the Cloudflare tunnel";
      Service = {
        ExecStart = pkgs.writeShellScript "cloudflared-watch" ''
          set -u
          url=https://nowplaying.tsukumo.f5.si/
          log=$HOME/.local/share/nowplaying/cf-watch.log
          mkdir -p "$(${pkgs.coreutils}/bin/dirname "$log")"
          systemctl=/run/current-system/sw/bin/systemctl
          mark=init
          i=0
          while true; do
            code=$(${pkgs.curl}/bin/curl -s -o /dev/null -w '%{http_code}' -m 15 "$url")
            rc=$?
            if [ "$rc" -ne 0 ]; then code="curl-$rc"; fi
            conns=$(${pkgs.iproute2}/bin/ss -Htn 'dport = :7844' 2>/dev/null | ${pkgs.coreutils}/bin/wc -l)
            tunnel=$($systemctl is-active cloudflared-tunnel-mouse-3 2>/dev/null || true)
            restarts=$($systemctl show cloudflared-tunnel-mouse-3 -p NRestarts --value 2>/dev/null || true)
            if [ "$code" != "$mark" ] || [ $((i % 30)) -eq 0 ]; then
              printf '%s code=%s conns=%s tunnel=%s restarts=%s\n' "$(${pkgs.coreutils}/bin/date -Is)" "$code" "$conns" "$tunnel" "$restarts" >> "$log"
              mark=$code
            fi
            i=$((i + 1))
            ${pkgs.coreutils}/bin/sleep 60
          done
        '';
        Restart = "always";
        RestartSec = 30;
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
