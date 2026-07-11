{
  lib,
  myLib,
  config,
  inputs,
  ...
}:
let
  myCfg = config.custom.security.clamav;
in
{
  imports = [
    inputs.nur.nixosModules.rclamonacc
  ];

  options.custom.security.clamav = {
    enable = myLib.mkEnabledOption;
    realtime = {
      enable = myLib.mkEnabledOption;
    };
  };
  config = {
    services.clamav = lib.mkIf myCfg.enable {
      scanner.enable = true;
      updater.enable = true;
      daemon.enable = true;
    };

    services.rclamonacc = lib.mkIf myCfg.realtime.enable {
      enable = true;
      settings.directories = [ "/home" ];
    };

    environment.persistence."/persist".directories = lib.mkIf myCfg.enable [
      {
        directory = "/var/lib/clamav";
        user = "clamav";
        group = "clamav";
        mode = "755";
      }
    ];
  };
}
