{ pkgs, lib, ... }:

{
  imports = [
  ];

  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-uuid/d480d1df-a949-4d5a-8a3e-58214637b087";
    allowDiscards = true;
  };

  boot.kernelParams = [
    "resume=/dev/mapper/vg-swap"
  ];

  boot.initrd.postDeviceCommands = lib.mkAfter ''
    mkdir -p /mnt
    mount -o subvolid=5 /dev/mapper/vg-root /mnt
    mkdir -p /mnt/old_roots

    if [ -e /mnt/old_roots/backup ]; then
      btrfs subvolume delete -R /mnt/old_roots/backup
    fi

    if [ -e /mnt/@root ]; then
      mv /mnt/@root /mnt/old_roots/backup
    fi

    btrfs subvolume create /mnt/@root

    umount /mnt
  '';

  # fileSystems."/" = {
  #   device = "none";
  #   fsType = "tmpfs";
  #   options = [ "defaults" "size=75%" "mode=755" ];
  # };
  fileSystems."/" = {
    device = "/dev/mapper/vg-root";
    fsType = "btrfs";
    options = [
      "subvol=@root"
      "compress=zstd"
      "noatime"
    ];
  };

  fileSystems."/nix" = {
    device = "/dev/mapper/vg-root";
    fsType = "btrfs";
    options = [
      "subvol=@nix"
      "compress=zstd"
      "noatime"
    ];
  };

  fileSystems."/persist" = {
    device = "/dev/mapper/vg-root";
    neededForBoot = true;
    fsType = "btrfs";
    options = [
      "subvol=@persist"
      "compress=zstd"
      "noatime"
    ];
  };

  services.btrbk = {
    instances = {
      "persist-snapshots" = {
        onCalendar = "hourly";
        settings = {
          snapshot_preserve_min = "2d";
          snapshot_preserve = "48h 7d 2w";
          volume."/persist" = {
            subvolume = ".";
            snapshot_dir = ".snapshots";
          };
        };
      };
    };
  };
  # for btrbk
  systemd.tmpfiles.rules = [
    "d /persist/.snapshots 0700 root root -"
  ];

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
  };

  # Swap の設定
  swapDevices = [
    { device = "/dev/mapper/vg-swap"; }
  ];

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # for Wi-Fi firmware
  hardware.firmware = [
    pkgs.linux-firmware
  ];

  hardware.graphics.enable = true;

  # bluetooth
  hardware.bluetooth.enable = true;
}
