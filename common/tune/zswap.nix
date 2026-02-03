{
  lib,
  config,
  myLib,
  ...
}:
{
  options.custom.tune.zswap.enable = myLib.mkEnabledOption;

  config = lib.mkIf config.custom.tune.zswap.enable {
    boot.kernelParams = [
      "zswap.enabled=1"
      "zswap.zpool=zsmalloc"
      "zswap.max_pool_percent=25"
    ];
  };
}
