{
  config,
  lib,
  mkEnabledOption,
  ...
}:
{
  options.custom.disk.disko = {
    enable = mkEnabledOption;
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
  };
  config = lib.mkIf config.custom.disk.disko.enable {
    disko.devices = {
      disk = {
        "main" = {
          type = "disk";
          device = config.custom.disko.diskName;
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                size = config.custom.disko.ESPSize;
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
                  name = "cryptedpart";
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
              size = config.custom.disko.swapSize;
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
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  "persist" = {
                    mountpoint = "/persist";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
		  "backup" = {
		    mountpoint = "/old";
		    mountOptions = [
		      "compress=zstd"
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
