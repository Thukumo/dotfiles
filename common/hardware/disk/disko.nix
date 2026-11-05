{
  config,
  lib,
  ...
}:
let
  cfg = config.custom.hardware.disk.disko;
in
{
  options.custom.hardware.disk.disko = lib.mkOption {
    type = lib.types.nullOr (
      lib.types.submodule {
        options = {
          diskName = lib.mkOption {
            type = lib.types.str;
            description = "Path to the disk device (e.g. /dev/disk/by-id/...)";
          };
          swapSize = lib.mkOption {
            type = lib.types.str;
            description = "Size of the swap partition (e.g. \"8G\")";
          };
          ESPSize = lib.mkOption {
            type = lib.types.str;
            default = "2G";
            description = "Size of the EFI System Partition (e.g. \"2G\")";
          };
          luks = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Enable LUKS encryption";
            };
            deviceName = lib.mkOption {
              type = lib.types.str;
              default = "cryptedpart";
              description = "Name of the LUKS device";
            };
          };
        };
      }
    );
    default = null;
    description = "Disk layout for disko. Set to null to disable disko.";
  };
  config = lib.mkIf (cfg != null) {
    disko.devices = {
      disk = {
        "main" = {
          type = "disk";
          device = cfg.diskName;
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                size = cfg.ESPSize;
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [ "umask=0077" ];
                };
              };
              luks = {
                size = "100%";
                content =
                  let
                    lvmPv = {
                      type = "lvm_pv";
                      vg = "vg";
                    };
                  in
                  if cfg.luks.enable then
                    {
                      type = "luks";
                      name = cfg.luks.deviceName;
                      settings.allowDiscards = true;
                      content = lvmPv;
                    }
                  else
                    lvmPv;
              };
            };
          };
        };
      };
      lvm_vg = {
        "vg" = {
          type = "lvm_vg";
          lvs = {
            swap = {
              size = cfg.swapSize;
              content = {
                type = "swap";
                discardPolicy = "both";
                resumeDevice = true;
              };
            };
            root = {
              size = "100%FREE";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  "root" = {
                    mountpoint = "/";
                    mountOptions = [
                      "compress-force=zstd"
                      "noatime"
                    ];
                  };
                  "nix" = {
                    mountpoint = "/nix";
                    mountOptions = [
                      "compress-force=zstd"
                      "noatime"
                    ];
                  };
                  "persist" = {
                    mountpoint = "/persist";
                    mountOptions = [
                      "compress-force=zstd"
                      "noatime"
                    ];
                  };
                  "backup" = {
                    mountpoint = "/old";
                    mountOptions = [
                      "compress-force=zstd"
                      "noatime"
                    ];
                  };
                };
              };
            };
          };
        };
      };
    };
    # set neededForBoot
    fileSystems."/persist".neededForBoot = true;
  };
}
