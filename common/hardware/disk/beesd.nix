{ config, lib, ... }:
{
  options.custom.hardware.disk.beesd = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    hashTableSizeMB = lib.mkOption {
      type = lib.types.int;
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
