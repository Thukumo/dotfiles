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
                IP="${pkgs.iproute2}/bin/ip"
                RESOLVECTL="${pkgs.systemd}/bin/resolvectl"

                if [ "''${reason:-}" = connect ]; then
                  OLD_DEFAULT="$($IP route show default 2>/dev/null || true)"
                  # Drop stale routes from an aborted session reusing this ifname,
                  # so vpnc-script doesn't snapshot them into its default-route backup.
                  $IP route flush dev "$IFACE" 2>/dev/null || true
                  $IP -6 route flush dev "$IFACE" 2>/dev/null || true
                fi

                # Keep openconnect's standard interface/route setup.
                # NOTE: vpnc-script runs under `set -e` and may abort mid-cleanup;
                # our connect/disconnect fix-ups below are idempotent and always run.
                ${pkgs.vpnc-scripts}/bin/vpnc-script || true

                case "''${reason:-}" in
                  connect)
                    # vpnc-script installs a full-tunnel default route; restore the
                    # pre-VPN default so only server-pushed split routes use the VPN.
                    # ponytail: naive save/restore, policy routing if this falls short
                    if [ -n "''${OLD_DEFAULT:-}" ]; then
                      $IP route del default dev "$IFACE" 2>/dev/null || true
                      echo "$OLD_DEFAULT" | while IFS= read -r r; do
                        [ -n "$r" ] || continue
                        # shellcheck disable=SC2086
                        $IP route replace $r 2>/dev/null || true
                      done
                    fi
                    $IP -6 route del default dev "$IFACE" 2>/dev/null || true
                    ${lib.optionalString (dnsDomains != [ ]) ''
                      ${pkgs.systemd}/bin/resolvectl domain "$IFACE" ${domainArgs}
                      ${pkgs.systemd}/bin/resolvectl default-route "$IFACE" no
                    ''}
                    $RESOLVECTL flush-caches
                    ;;
                  disconnect)
                    # Finish what vpnc-script may have aborted: no tun routes or
                    # per-link DNS may leak into the next session.
                    $IP route flush dev "$IFACE" 2>/dev/null || true
                    $IP -6 route flush dev "$IFACE" 2>/dev/null || true
                    $RESOLVECTL revert "$IFACE" 2>/dev/null || true
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
          home.persistence."/persist" = {
            directories = [
              ".local/share/.gp-saml-gui-wrapped"
              ".cache/.gp-saml-gui-wrapped"
            ];
            files = [ ".gp-saml-gui-cookies" ];
          };
        }
      );
}
