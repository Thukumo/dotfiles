{ config, lib, ... }:
let
  cfg = config.custom.hardware.disk.beesd;
in
{
  options.custom.hardware.disk.beesd = lib.mkOption {
    type = lib.types.nullOr (
      lib.types.submodule {
        options.hashTableSizeMB = lib.mkOption {
          type = lib.types.int;
          description = "Size of the beesd hash table in MiB";
        };
      }
    );
    default = null;
    description = "beesd btrfs deduplication. Set hashTableSizeMB to enable; null disables it.";
  };
  config = lib.mkIf (cfg != null) {
    services.beesd.filesystems."root" = {
      spec = "/";
      verbosity = "warning";
      inherit (cfg) hashTableSizeMB;
    };
  };
}
