{ lib, config, ... }:

let
  wifiList = {
    "φ2" = {
      name = "phi2";
      f = pwdVar: { pskRaw = pwdVar; };
    };
    "AP80211-5n" = {
      name = "5n";
      f = p: { pskRaw = p; };
    };
  };
  mkConf = essid: val: (val.f "ext:${val.name or essid}_pwd");
in
{
  systemd.services."wpa_supplicant".serviceConfig.BindReadOnlyPaths = [
    config.age.secrets.eduroam.path
  ];
  networking.wireless = {
    enable = true;
    secretsFile = config.age.secrets.wifi-pwds.path;
    extraConfigFiles = [
      # PR通るまで待つ
      config.age.secrets.eduroam.path
    ];
    networks = lib.mapAttrs mkConf wifiList;
  };
}
