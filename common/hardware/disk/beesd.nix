{ config, lib, ... }:
{
  options.custom.hardware.disk.beesd = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.custom.hardware.disk.disko.enable;
    };
    hashTableSizeMB = lib.mkOption {
      type = lib.types.int;
    };
  };
  config = lib.mkIf config.custom.hardware.disk.beesd.enable {
    services.beesd.filesystems."root" = {
      spec = "/";
      verbosity = "warning";
      inherit (config.custom.hardware.disk.beesd) hashTableSizeMB;
    };
  };
}
