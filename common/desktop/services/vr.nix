{
  config,
  lib,
  pkgs,
  desktopLib,
  myLib,
  ...
}:
{
  config =
    let
      vrEnabled = myLib.anyUser config (user: user.desktop.vr.enable);
    in
    {
      environment.systemPackages = lib.mkIf vrEnabled [
        pkgs.wayvr
      ];

      services.wivrn = lib.mkIf vrEnabled {
        enable = true;
        autoStart = true;
        openFirewall = true;
        config = {
          enable = true;
          json = {
            scale = 1.0;
            framerate = 72;
            encoders = [
              {
                encoder = "nvenc";
                codec = "hevc";
              }
            ];
          };
        };
      };

      home-manager.users = desktopLib.mkHome (user: user.custom.desktop.vr.enable) (_: {
        home.persistence."/persist".directories = [
          ".config/wivrn"
          ".config/wayvr"
        ];
        home.sessionVariables = {
          PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES = "1";
        };
      });
    };
}
