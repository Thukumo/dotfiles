{ config, lib, ... }:
{
  options.custom.hardware.disk.btrfs-autoScrub = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.custom.hardware.disk.disko.enable;
    };
  };
  config = lib.mkIf config.custom.hardware.disk.btrfs-autoScrub.enable {
    services.btrfs.autoScrub = {
      enable = true;
      fileSystems = [ "/" ];
      interval = "weekly";
    };
  };
}
