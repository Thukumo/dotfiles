{
  inputs,
  config,
  ...
}:

{
  security.tpm2.enable = false;

  services.journald.storage = "volatile";
  services.journald.extraConfig = ''
    RuntimeMaxUse=64M
    RuntimeKeepFree=64M
    MaxRetentionSec=2days
  '';

  # "intel_pstate: Turbo disabled by BIOS"がdmesgに出続けるのを抑止
  services.auto-cpufreq.settings = {
    charger.turbo = "never";
    battery.turbo = "never";
  };

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
        opencode.enable = true;
      };
    };
  };

  home-manager.users."tsukumo" = {
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
        environment.NOWPLAYING_BIND = "127.0.0.1:8181";
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
  };

  # agenix system key (for secrets not tied to a specific user)
  custom.secrets.extraIdentityPaths = [ "/etc/age/key.txt" ];
  environment.persistence."/persist".directories = [
    "/etc/age"
  ];

  age.secrets."cloudflared_nowplaying".file = ./cloudflared-nowplaying-credentials.age;
  services.cloudflared = {
    enable = true;
    tunnels.mouse-3 = {
      credentialsFile = config.age.secrets.cloudflared_nowplaying.path;
      default = "http_status:404";
      ingress."*.tsukumo.f5.si".service = "http://127.0.0.1:8182";
    };
  };

  services.nginx = {
    enable = true;
    virtualHosts = {
      "api-nowplaying.tsukumo.f5.si" = {
        listen = [
          {
            addr = "127.0.0.1";
            port = 8182;
          }
        ];
        locations."/" = {
          proxyPass = "http://127.0.0.1:8181";
        };
      };
      "nowplaying.tsukumo.f5.si" = {
        listen = [
          {
            addr = "127.0.0.1";
            port = 8182;
          }
        ];
        locations."/" = {
          proxyPass = "http://127.0.0.1:8183";
        };
      };
      "_" = {
        listen = [
          {
            addr = "127.0.0.1";
            port = 8182;
          }
        ];
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

  console.keyMap = "jp106";
  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "jp106";
    variant = "";
  };

  system.stateVersion = "26.05";
}
