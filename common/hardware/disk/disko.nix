{
  config,
  lib,
  myLib,
  ...
}:
{
  options.custom.hardware.disk.disko = {
    enable = myLib.mkEnabledOption;
    diskName = lib.mkOption {
      type = lib.types.str;
    };
    swapSize = lib.mkOption {
      type = lib.types.str;
    };
    ESPSize = lib.mkOption {
      type = lib.types.str;
      default = "2G";
    };
    luksDeviceName = lib.mkOption {
      type = lib.types.str;
      default = "cryptedpart";
      description = "Name of the LUKS device";
    };
  };
  config = lib.mkIf config.custom.hardware.disk.disko.enable {
    disko.devices = {
      disk = {
        "main" = {
          type = "disk";
          device = config.custom.hardware.disk.disko.diskName;
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                size = config.custom.hardware.disk.disko.ESPSize;
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
                content = {
                  type = "luks";
                  name = config.custom.hardware.disk.disko.luksDeviceName;
                  settings.allowDiscards = true;
                  content = {
                    type = "lvm_pv";
                    vg = "vg";
                  };
                };
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
              size = config.custom.hardware.disk.disko.swapSize;
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
