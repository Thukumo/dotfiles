{
  lib,
  mkForEachUsers,
  config,
  ...
}:
{
  options.users.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { ... }:
        {
          options.custom.network.globalProtect.enable = lib.mkEnableOption "GlobalProtect VPN";
        }
      )
    );
  };

  config =
    let
      vpnPortal = "gpvpn.sic.shibaura-it.ac.jp";
    in
    lib.mkIf
      (builtins.any (user: user.custom.network.globalProtect.enable) (
        builtins.attrValues config.users.users
      ))
      {
        systemd.network.networks."50-sras-vpn" = {
          matchConfig.Name = "sras-vpn";

          routes = [
            { routeConfig.Destination = "133.68.0.0/16"; }
            { routeConfig.Destination = "172.16.0.0/12"; }
            { routeConfig.Destination = "202.18.120.0/24"; }
          ];

          networkConfig = {
            DNSDefaultRoute = false;
            domains = [
              "~shibaura-it.ac.jp"
              "~sic.shibaura-it.ac.jp"
            ];
            DNS = [
              "133.68.5.45"
              "133.68.5.51"
            ];
          };
          linkConfig.RequiredForOnline = "no";
        };
        home-manager.users = mkForEachUsers (user: user.custom.network.globalProtect.enable) (
          user:
          { config, pkgs, ... }:
          {
            home.packages = [
              (pkgs.writeShellScriptBin "vpn-connect" ''
                  eval $(${pkgs.gp-saml-gui}/bin/gp-saml-gui \
                    --gateway \
                    --clientos=Linux \
                ${vpnPortal})
                  echo user $USER
                  echo "$COOKIE" | sudo ${pkgs.openconnect}/bin/openconnect \
                    --protocol=gp \
                    --interface="sras-vpn" \
                    --user="$USER" \
                    --os="$OS" \
                    --passwd-on-stdin \
                    --script="${pkgs.vpnc-scripts}/etc/vpnc/vpnc-script" \
                    "$HOST"
              '')
            ];
            home.persistence."/persist".directories = [
              ".local/share/.gp-saml-gui-wrapped"
              ".cache/.gp-saml-gui-wrapped"
            ];
          }
        );
      };
}
