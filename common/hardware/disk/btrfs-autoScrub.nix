{ config, lib, ... }:
{
  options.custom.hardware.disk.btrfs-autoScrub = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable btrfs auto scrub";
    };
  };
  config = lib.mkMerge [
    {
      custom.hardware.disk.btrfs-autoScrub.enable =
        lib.mkDefault config.custom.hardware.disk.disko.enable;
    }
    (lib.mkIf config.custom.hardware.disk.btrfs-autoScrub.enable {
      services.btrfs.autoScrub = {
        enable = true;
        fileSystems = [ "/" ];
        interval = "weekly";
      };
    })
  ];
}
