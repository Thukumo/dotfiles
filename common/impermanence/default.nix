{
  lib,
  config,
  myLib,
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

    home-manager.users = myLib.mkForEachUsers (_: true) (user: {
      home.persistence."/persist" = {
        directories = config.custom.users.${user.name}.persistence.directories or [ ];
        files = config.custom.users.${user.name}.persistence.files or [ ];
      };
    });

    # Trashの削除
    systemd.tmpfiles.rules =
      lib.flatten (
        lib.mapAttrsToList (
          name: user:
          let
            dirPaths = builtins.map (dir: if builtins.isString dir then dir else dir.directory) (
              config.home-manager.users."${name}".home.persistence."/persist".directories or [ ]
            );
          in
          builtins.map (dir: "R! /persist${user.home}/${dir}/.Trash-* - - - -") dirPaths
        ) (lib.filterAttrs (_: user: user.isNormalUser) config.users.users)
      )
      ++ [
        "d /var/lib/private 0700 root root -"
      ];

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
