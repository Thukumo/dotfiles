_:

{
  boot.kernelParams = [
  ];

  custom = {
    network = {
      mycelium.enable = true;
      cloudflare-warp.enable = false;
      ssh-server.enable = true;
    };
    # hardware.keybind.enable = false;
    users."tsukumo" = {
      network.dlna = {
        enable = true;
        mediaDirs = [ "V,Documents/mov" ];
      };
      network.globalProtect.enable = true;
      desktop = {
        enable = false;
      };
      dev = {
        podman.enable = true;
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
