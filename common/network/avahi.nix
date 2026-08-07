{
  lib,
  config,
  myLib,
  ...
}:
{
  options.custom.network.avahi = {
    enable = myLib.mkEnabledOption "avahi (mDNS/DNS-SD)";
  };

  config = lib.mkIf config.custom.network.avahi.enable {
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      nssmdns6 = true;
    };
  };
}
