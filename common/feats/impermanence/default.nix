{ lib, config, ... }:

{
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/etc/NetworkManager/system-connections"
      "/var/lib/NetworkManager/system-connections"
      "/var/lib/bluetooth"
      "/var/lib/systemd/timers"
      "/var/lib/nixos"
      "/var/log"
    ];
    files = [ "/etc/machine-id" ];
  };
  # for "home-manager" impermanence
  programs.fuse.userAllowOther = true;
  home-manager.users."tsukumo".imports = [
    ./home-impermanence.nix
  ];
  boot.initrd.postDeviceCommands = lib.mkIf config.custom.disko.enable (
    lib.mkAfter ''
      mkdir -p /mnt
      mount -o subvolid=5 /dev/vg/root /mnt

      if [ -e /mnt/backup ]; then
        btrfs subvolume delete -R /mnt/backup
      fi

      if [ -e /mnt/root ]; then
        mv /mnt/root /mnt/backup
      fi

      btrfs subvolume create /mnt/root

      umount /mnt
    ''
  );
}
