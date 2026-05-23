{
  config,
  lib,
  pkgs,
  desktopLib,
  ...
}:
{
  config =
    let
      vrEnabled = builtins.any (user: user.desktop.vr.enable or false) (
        builtins.attrValues config.custom.users
      );
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

      # Enable Avahi daemon for service discovery, required by wivrn.
      # Only set values when VR is enabled (avoid writing an explicit `false`,
      # which can conflict with other modules also using mkDefault).
      services.avahi.enable = lib.mkIf vrEnabled (lib.mkDefault true);
      services.avahi.publish.enable = lib.mkIf vrEnabled (lib.mkDefault true);
      services.avahi.publish.userServices = lib.mkIf vrEnabled (lib.mkDefault true);
      home-manager.users = desktopLib.mkHome (user: user.custom.desktop.vr.enable or false) (_: {
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
