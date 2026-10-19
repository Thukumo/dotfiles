{
  inputs,
  config,
  pkgs,
  ...
}:

{
  security.tpm2.enable = false;

  services.journald = {
    storage = "volatile";
    settings.Journal = {
      RuntimeMaxUse = "64M";
      RuntimeKeepFree = "64M";
      MaxRetentionSec = "2days";
    };
  };

  # どうせクロック周波数が変動しないので
  custom.hardware.tune.auto-cpufreq.enable = false;

  custom = {
    style.plymouth.enable = false;
    network = {
      mycelium.enable = true;
      cloudflare-warp.enable = false;
      ssh-server.enable = true;
    };
    hardware.keyboard.keybind.enable = false;
    security.clamav.realtime.enable = false;
    users."tsukumo" = {
      account.userConfig.linger = true;
      desktop.enable = false;
      dev = {
        podman.enable = true;
        opencode.web.enable = true;
        pi.enable = true;
      };
    };
  };

  home-manager.users."tsukumo" = {
    home.persistence."/persist".directories = [ ".local/share/nowplaying" ];

    age.secrets."nowplaying_token".file = ../../common/desktop/services/nowplaying/nowplaying-token.age;

    services.podman.containers = {
      # https://stepney141.hatenablog.com/entry/2025/02/17/182148
      archiveteam = {
        image = "atdr.meo.ws/archiveteam/warrior-dockerfile";
        ports = [ "127.0.0.1:8080:8001" ];
        autoUpdate = "registry";
        environment = {
          "DOWNLOADER" = "tsukumo";
          "SELECTED_PROJECT" = "auto";
          "CONCURRENT_ITEMS" = 2;
        };
        extraPodmanArgs = [
          "--tmpfs"
          "/home/warrior/data/projects"
        ];
        extraConfig.Service = {
          # 実はsystemd側でAlwaysにされるから書く意味ない(明示したいだけ)
          Restart = "always";
          TimeoutStopSec = 300;
          KillSignal = "SIGINT";
        };
      };

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

  # agenix system key (for secrets not tied to a specific user)
  custom.secrets.systemAgeKey.enable = true;

  age.secrets."cloudflared_nowplaying".file = ./cloudflared-nowplaying-credentials.age;
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

  services.glances = {
    enable = true;
    extraArgs = [
      "--webserver"
      "--bind"
      "127.0.0.1"
      "--hide-public-info"
      "--disable-check-update"
      # プロセス一覧(コマンドライン)・接続先IP・リッスンポート・IPアドレスを隠す
      # (--disable-process は UI にしか効かず API から見えるのでプラグイン単位で無効化)
      "--disable-plugin"
      "processlist,programlist,connections,ports,ip"
    ];
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

  custom.hardware.disk = {
    btrfs-autoScrub.enable = true;
    beesd = {
      enable = false;
      hashTableSizeMB = 256;
    };
    disko = {
      enable = true;
      diskName = "/dev/disk/by-id/ata-ADATA_SP550_2G1620018123";
      swapSize = "10G";
      luks.enable = false;
    };
  };

  system.stateVersion = "26.05";
}
