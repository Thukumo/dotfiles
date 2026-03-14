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
        directories = user.custom.persistence.directories or [ ];
        files = user.custom.persistence.files or [ ];
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

    boot.initrd.systemd.services.rollback = lib.mkIf config.custom.hardware.disk.disko.enable {
      description = "Rollback Btrfs root subvolume";
      wantedBy = [ "initrd.target" ];
      after = [ "dev-vg-root.device" ];
      before = [ "sysroot.mount" ];
      conflicts = [ "initrd-switch-root.target" ];
      unitConfig.DefaultDependencies = "no";
      serviceConfig.Type = "oneshot";
      script = ''
        mkdir -p /mnt
        mount -t btrfs -o subvolid=5 /dev/vg/root /mnt

        if [ -e /mnt/backup ]; then
          btrfs subvolume delete -R /mnt/backup
        fi

        if [ -e /mnt/root ]; then
          mv /mnt/root /mnt/backup
        fi

        btrfs subvolume create /mnt/root

        umount /mnt
      '';
    };
  };
}
