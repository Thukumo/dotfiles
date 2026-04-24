{
  lib,
  myLib,
  ...
}:
{
  options.custom.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (_: {
        options.network.globalProtect = {
          enable = lib.mkEnableOption "GlobalProtect VPN";
          vpnPortal = lib.mkOption {
            type = lib.types.str;
            default = "gpvpn.sic.shibaura-it.ac.jp";
          };
          dnsDomains = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ "shibaura-it.ac.jp" ];
          };
        };
      })
    );
  };

  config.home-manager.users =
    myLib.mkForEachUsers (user: user.custom.network.globalProtect.enable or false)
      (
        user:
        { pkgs, ... }:
        let
          vpnInterface = "open-connect";
          dnsDomains = map (
            domain: if lib.hasPrefix "~" domain then domain else "~${domain}"
          ) user.custom.network.globalProtect.dnsDomains;
          domainArgs = lib.concatStringsSep " " (map lib.escapeShellArg dnsDomains);
        in
        {
          home.packages = [
            (pkgs.writeShellScriptBin "vpn-connect" ''
              set -euo pipefail

              eval "$(${pkgs.gp-saml-gui}/bin/gp-saml-gui \
                --gateway \
                --clientos=Linux \
                ${user.custom.network.globalProtect.vpnPortal})"

              VPN_SCRIPT="${pkgs.writeShellScript "vpn-dns-script.sh" ''
                set -euo pipefail

                # Keep openconnect's standard interface/route setup.
                ${pkgs.vpnc-scripts}/bin/vpnc-script

                IFACE="''${TUNDEV:-${vpnInterface}}"

                case "''${reason:-}" in
                  connect)
                    ${lib.optionalString (dnsDomains != [ ]) ''
                      ${pkgs.systemd}/bin/resolvectl domain "$IFACE" ${domainArgs}
                      ${pkgs.systemd}/bin/resolvectl default-route "$IFACE" no
                    ''}
                    ${pkgs.systemd}/bin/resolvectl flush-caches
                    ;;
                esac
              ''}"

              echo "$COOKIE" | sudo ${pkgs.openconnect}/bin/openconnect \
                --protocol=gp \
                --interface="${vpnInterface}" \
                --user="$USER" \
                --no-dtls \
                --passwd-on-stdin \
                --csd-wrapper "${pkgs.openconnect}/libexec/openconnect/hipreport.sh" \
                --script "$VPN_SCRIPT" \
                "https://${user.custom.network.globalProtect.vpnPortal}/gateway:prelogin-cookie"
            '')
          ];
          home.persistence."/persist".directories = [
            ".local/share/.gp-saml-gui-wrapped"
            ".cache/.gp-saml-gui-wrapped"
          ];
        }
      );
}
