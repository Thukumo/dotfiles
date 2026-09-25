{
  lib,
  myLib,
  config,
  ...
}:
{
  options.custom.users = myLib.mkUserOption (_: {
    options.network.globalProtect = {
      enable = lib.mkEnableOption "GlobalProtect VPN";
      vpnPortal = lib.mkOption {
        type = lib.types.str;
        default = "gpvpn.sic.shibaura-it.ac.jp";
        description = "GlobalProtect portal address";
      };
      dnsDomains = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "shibaura-it.ac.jp" ];
        description = "DNS domains routed through the VPN";
      };
    };
  });

  config.home-manager.users =
    myLib.mkForEachUsers config (user: user.custom.network.globalProtect.enable)
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

                IFACE="''${TUNDEV:-${vpnInterface}}"
                if [ "''${reason:-}" = connect ]; then
                  OLD_DEFAULT="$(${pkgs.iproute2}/bin/ip route show default 2>/dev/null || true)"
                fi

                # Keep openconnect's standard interface/route setup.
                ${pkgs.vpnc-scripts}/bin/vpnc-script

                case "''${reason:-}" in
                  connect)
                    # vpnc-script installs a full-tunnel default route; restore the
                    # pre-VPN default so only server-pushed split routes use the VPN.
                    # ponytail: naive save/restore, policy routing if this falls short
                    if [ -n "''${OLD_DEFAULT:-}" ]; then
                      ${pkgs.iproute2}/bin/ip route del default dev "$IFACE" 2>/dev/null || true
                      echo "$OLD_DEFAULT" | while IFS= read -r r; do
                        [ -n "$r" ] || continue
                        # shellcheck disable=SC2086
                        ${pkgs.iproute2}/bin/ip route replace $r 2>/dev/null || true
                      done
                    fi
                    ${pkgs.iproute2}/bin/ip -6 route del default dev "$IFACE" 2>/dev/null || true
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
