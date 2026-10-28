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

      # Enable Avahi daemon for service discovery, required by wivrn.
      # wivrn モジュールは廃止済みの publish.* を設定して警告を出すため、
      # 新オプションをここで設定し、旧オプションは null にして警告を止める。
      services.avahi.enable = lib.mkIf vrEnabled (lib.mkDefault true);
      services.avahi.publish.enable = lib.mkIf vrEnabled (lib.mkForce null);
      services.avahi.publish.userServices = lib.mkIf vrEnabled (lib.mkForce null);
      services.avahi.settings.publish.disable-publishing = lib.mkIf vrEnabled (lib.mkDefault false);
      services.avahi.settings.publish.disable-user-service-publishing = lib.mkIf vrEnabled (
        lib.mkDefault false
      );
      services.avahi.settings.publish.publish-addresses = lib.mkIf vrEnabled (lib.mkDefault true);
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
