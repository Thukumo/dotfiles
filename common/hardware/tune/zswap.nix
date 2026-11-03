{
  lib,
  config,
  myLib,
  ...
}:
{
  options.custom.hardware.tune.zswap = {
    enable = myLib.mkEnabledOption "zswap";
    maxPoolPercent = lib.mkOption {
      type = lib.types.ints.between 1 100;
      default = 25;
      description = "Maximum zswap pool size as a percentage of RAM.";
    };
  };

  config = lib.mkIf config.custom.hardware.tune.zswap.enable {
    boot.kernelParams = [
      "zswap.enabled=1"
      "zswap.zpool=zsmalloc"
      "zswap.max_pool_percent=${toString config.custom.hardware.tune.zswap.maxPoolPercent}"
    ];
  };
}
