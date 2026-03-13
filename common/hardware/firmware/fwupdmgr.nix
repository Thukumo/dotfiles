{
  lib,
  config,
  myLib,
  ...
}:

{
  options.custom.hardware.fwupdmgr.enable = myLib.mkEnabledOption;

  config = lib.mkIf config.custom.hardware.fwupdmgr.enable {
    services.fwupd.enable = true;
    environment.persistence."/persist".directories = [
      "/var/lib/fwupd"
    ];
  };
}
