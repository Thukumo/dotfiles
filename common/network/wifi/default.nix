{ lib, config, ... }:
{
  options.custom.network.wifi.fallbackToWPA2 = lib.mkEnableOption "gen config for WPA2";
  config =
    let
      wifiList = {
        "φ2" = {
          name = "phi2";
          f = p: { pskRaw = p; };
        };
        "X4S".f = p: { pskRaw = p; };
        "AP80211-5n" = {
          name = "5n";
          f = p: { pskRaw = p; };
        };
        "DigicreWiFi".f = p: { pskRaw = p; };
      };
      mkConf = essid: val: (val.f "ext:${val.name or essid}_pwd");
    in
    {
      # PR通るまで待つ
      systemd.services."wpa_supplicant".serviceConfig.BindReadOnlyPaths = [
        config.age.secrets.eduroam.path
      ];
      networking.wireless = {
        enable = true;
        inherit (config.custom.network.wifi) fallbackToWPA2;
        userControlled = true;
        secretsFile = config.age.secrets.wifi-pwds.path;
        extraConfigFiles = [
          config.age.secrets.eduroam.path
        ];
        networks = lib.mapAttrs mkConf wifiList;
      };

      age.secrets = {
        "wifi-pwds" = {
          file = ./pwds.age;
          owner = "wpa_supplicant";
          group = "wpa_supplicant";
          mode = "400";
        };
        "eduroam" = {
          file = ./eduroam.age;
          owner = "wpa_supplicant";
          group = "wpa_supplicant";
          mode = "400";
        };
      };
    };
}
