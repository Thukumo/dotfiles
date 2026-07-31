_:

{
  custom = {
    style.plymouth.enable = false;
    network = {
      mycelium.enable = true;
      cloudflare-warp.enable = false;
      ssh-server.enable = true;
    };
    hardware.keyboard.keybind.enable = false;
    users."tsukumo" = {
      account.userConfig.linger = true;
      desktop.enable = false;
      dev = {
        podman.enable = true;
        opencode.enable = true;
      };
    };
  };

  # https://stepney141.hatenablog.com/entry/2025/02/17/182148
  home-manager.users."tsukumo" = {
    services.podman.containers.archiveteam = {
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
  };

  # agenix system key (for secrets not tied to a specific user)
  custom.secrets.extraIdentityPaths = [ "/etc/age/key.txt" ];
  environment.persistence."/persist".directories = [
    "/etc/age"
  ];

  custom.hardware.disk = {
    btrfs-autoScrub.enable = true;
    beesd = {
      enable = true;
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
