{
  lib,
  config,
  mkForEachUsers,
  ...
}:

{
  config = {
    environment.persistence."/persist" = {
      hideMounts = true;
      directories = [
        "/etc/NetworkManager/system-connections"
        "/var/lib/NetworkManager/system-connections"
        "/var/lib/bluetooth"
        "/var/lib/systemd/backlight"
        "/var/lib/systemd/timers"
        "/var/lib/nixos"
        "/var/log"
      ];
      files = [ "/etc/machine-id" ];
    };

    home-manager.users = mkForEachUsers (_: true) (user: {
      home.persistence."/persist" = {
        directories = user.custom.persistence.directories;
        files = user.custom.persistence.files;
      };
    });

    systemd.tmpfiles.rules = [
      "d /persist/home 0755 root root -"
    ]
    ++ lib.flatten (
      lib.mapAttrsToList (
        name: user: lib.optional user.isNormalUser "d /persist${user.home} 0700 ${name} users - -"
      ) config.users.users
    );

    boot.initrd.postDeviceCommands = lib.mkIf config.custom.disk.disko.enable (
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
  };
}
