{
  lib,
  config,
  myLib,
  ...
}:
{
  options.custom.hardware.tune.zswap.enable = myLib.mkEnabledOption;

  config = lib.mkIf config.custom.hardware.tune.zswap.enable {
    boot.kernelParams = [
      "zswap.enabled=1"
      "zswap.zpool=zsmalloc"
      "zswap.max_pool_percent=25"
    ];
  };
}
