{ lib, config, ... }:

let
  wifiList = {
    "φ2" = {
      name = "phi2";
      f = pwdVar: {
        pskRaw = pwdVar;
      };
    };
    "eduroam" = {
      f = pwdVar: {
        auth = ''
          key_mgmt=WPA-EAP
          eap=PEAP
          identity="@eduroam_identity@"
          password=${pwdVar}
          phase2="auth=MSCHAPV2"
        '';
      };
    };
  };
  mkConf = essid: val: (val.f "ext:${val.name or essid}_pwd");
in
{
  networking.wireless = {
    enable = true;
    secretsFile = config.age.secrets.wifi-secrets.path;
    networks = lib.mapAttrs mkConf wifiList;
  };
}
