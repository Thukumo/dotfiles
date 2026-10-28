_:

{
  # どうせクロック周波数が変動しないので
  custom.hardware.tune.auto-cpufreq.enable = false;

  custom.hardware.disk = {
    btrfs-autoScrub.enable = true;
    beesd = {
      enable = false;
      hashTableSizeMB = 256;
    };
    disko = {
      enable = true;
      diskName = "/dev/disk/by-id/ata-ADATA_SP550_2G1620018123";
      swapSize = "10G";
      luks.enable = false;
    };
  };
}
