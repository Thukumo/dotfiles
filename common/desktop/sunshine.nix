{
  lib,
  config,
  ...
}:

{
  config = lib.mkIf config.custom.desktop.sunshine.enable {
    boot.kernelParams = [ "video=HEADLESS-1:1280x800e" ];
    services.sunshine = {
      enable = true;
      openFirewall = true;
      capSysAdmin = true;
      settings = {
        output_name = "HEADLESS-1";
      };
    };
  };
}
