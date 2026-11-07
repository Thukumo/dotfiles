{
  lib,
  config,
  ...
}:

{
  options.custom.network.wifi = {
    enable = lib.mkEnableOption "wpa_supplicant Wi-Fi";
    fallbackToWPA2 = lib.mkEnableOption "gen config for WPA2";
  };

  config = lib.mkIf config.custom.network.wifi.enable {
    networking.wireless = {
      enable = true;
      inherit (config.custom.network.wifi) fallbackToWPA2;
      userControlled = true;
      secretsFile = config.age.secrets.wifi-pwds.path;
      extraConfigFiles = [
        config.age.secrets.eduroam.path
      ];
      networks = {
        "φ2".pskRaw = "ext:phi2_pwd";
        "X4S".pskRaw = "ext:X4S_pwd";
        "AP80211-5n".pskRaw = "ext:5n_pwd";
        "DigicreWiFi".pskRaw = "ext:DigicreWiFi_pwd";
      };
    };

    custom.secrets.access.system = {
      "wifi-pwds" = {
        file = ./pwds.age;
        kind = "owner";
        trusted = true;
        owner = "wpa_supplicant";
        group = "wpa_supplicant";
      };
      "eduroam" = {
        file = ./eduroam.age;
        kind = "owner";
        trusted = true;
        owner = "wpa_supplicant";
        group = "wpa_supplicant";
      };
    };
  };
}
