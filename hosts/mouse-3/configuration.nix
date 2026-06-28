{ config, lib, ... }:

{
  boot.kernelParams = [
  ];

  custom = {
    style.plymouth.enable = false;
    network = {
      mycelium.enable = true;
      cloudflare-warp.enable = false;
      ssh-server.enable = true;
    };
    hardware.keyboard.keybind.enable = false;
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

  boot.initrd = {
    availableKernelModules = [ "r8169" ];
    secrets."/etc/ssh/ssh_host_ed25519_key" = lib.mkForce config.age.secrets.initrd_ssh_host_key.path;
    network = {
      enable = true;
      ssh = {
        enable = true;
        authorizedKeyFiles = config.users.users.tsukumo.openssh.authorizedKeys.keyFiles;
        hostKeys = [
          "/etc/ssh/ssh_host_ed25519_key"
        ];
      };
    };
  };
  age.secrets.initrd_ssh_host_key.file = ./initrd-ssh.age;

  system.stateVersion = "26.05";
}
