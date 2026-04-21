{
  lib,
  config,
  myLib,
  ...
}:
{
  options.custom.network.avahi = {
    enable = myLib.mkEnabledOption;
  };

  config = lib.mkIf config.custom.network.avahi.enable {
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      nssmdns6 = true;
    };
  };
}
