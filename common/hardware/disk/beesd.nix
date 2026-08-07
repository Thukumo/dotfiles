{ config, lib, ... }:
{
  options.custom.hardware.disk.beesd = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable beesd (btrfs deduplication)";
    };
    hashTableSizeMB = lib.mkOption {
      type = lib.types.int;
      description = "Size of the beesd hash table in MiB";
    };
  };
  config = lib.mkMerge [
    {
      custom.hardware.disk.beesd.enable = lib.mkDefault config.custom.hardware.disk.disko.enable;
    }
    (lib.mkIf config.custom.hardware.disk.beesd.enable {
      services.beesd.filesystems."root" = {
        spec = "/";
        verbosity = "warning";
        inherit (config.custom.hardware.disk.beesd) hashTableSizeMB;
      };
    })
  ];
}
