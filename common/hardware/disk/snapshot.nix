{ config, lib, ... }:
{
  options.custom.hardware.disk.snapshot = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable btrbk snapshots of /persist";
    };
    # directory = ?
  };
  config = lib.mkMerge [
    {
      custom.hardware.disk.snapshot.enable = lib.mkDefault config.custom.hardware.disk.disko.enable;
    }
    (lib.mkIf config.custom.hardware.disk.snapshot.enable {
      # btrbk for /persist
      systemd.tmpfiles.rules = [
        "d /persist/.snapshots 0700 root root -"
      ];
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
    })
  ];
}
