{
  lib,
  myLib,
  config,
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
        };
      })
    );
  };

  config =
    let
      vpnInterface = "open-connect";
      campusRoutes = [
        "133.68.0.0/16"
        "172.16.0.0/12"
        "202.18.0.0/16"
      ];
      campusDomains = [
        "~ami.sic.shibaura-it.ac.jp"
        "~shibaura-it.ac.jp"
        "~sic.shibaura-it.ac.jp"
      ];
      campusDns = [
        "133.68.5.45"
        "133.68.5.51"
      ];
    in
    lib.mkIf
      (builtins.any (userConfig: userConfig.network.globalProtect.enable or false) (
        builtins.attrValues config.custom.users
      ))
      {
        systemd.network.networks."50-${vpnInterface}" = {
          matchConfig.Name = vpnInterface;
          routes = map (destination: { routeConfig.Destination = destination; }) campusRoutes;

          networkConfig = {
            DNSDefaultRoute = false;
            Domains = campusDomains;
            DNS = campusDns;
          };
          linkConfig.RequiredForOnline = "no";
        };

        home-manager.users =
          myLib.mkForEachUsers (user: user.custom.network.globalProtect.enable or false)
            (
              user:
              { pkgs, ... }:
              let
                campusDnsFallback = lib.concatStringsSep " " campusDns;
                campusDomainArgs = lib.concatStringsSep " " (map lib.escapeShellArg campusDomains);
                staticCampusRouteCommands = lib.concatMapStringsSep "\n" (
                  destination: ''${pkgs.iproute2}/bin/ip route replace ${destination} dev "$IFACE"''
                ) campusRoutes;
                openconnectUrl = "https://${user.custom.network.globalProtect.vpnPortal}/gateway:prelogin-cookie";
              in
              {
                home.packages = [
                  (pkgs.writeShellScriptBin "vpn-connect" ''
                    eval $(${pkgs.gp-saml-gui}/bin/gp-saml-gui \
                      --gateway \
                      --clientos=Linux \
                      ${user.custom.network.globalProtect.vpnPortal})

                    # VPN script for TUN interface setup
                    VPN_SCRIPT="${pkgs.writeShellScript "vpn-script.sh" ''
                                            set -e
                                            exec 1>/tmp/vpn-script.log 2>&1

                                            mask_to_prefix() {
                                              local mask="$1"
                                              local IFS=.
                                              local -a octets
                                              local bits=0

                                              read -r -a octets <<<"$mask"
                                              for octet in "''${octets[@]}"; do
                                                case "$octet" in
                                                  255) bits=$((bits + 8)) ;;
                                                  254) bits=$((bits + 7)) ;;
                                                  252) bits=$((bits + 6)) ;;
                                                  248) bits=$((bits + 5)) ;;
                                                  240) bits=$((bits + 4)) ;;
                                                  224) bits=$((bits + 3)) ;;
                                                  192) bits=$((bits + 2)) ;;
                                                  128) bits=$((bits + 1)) ;;
                                                  0) ;;
                                                  *) return 1 ;;
                                                esac
                                              done

                                              echo "$bits"
                                            }

                                            ensure_gateway_route() {
                                              case "''${VPNGATEWAY:-}" in
                                                ""|*[!0-9.]*)
                                                  return 0
                                                  ;;
                                              esac

                                              default_route="$(${pkgs.iproute2}/bin/ip -4 route show default | ${pkgs.coreutils}/bin/head -n1)"
                                              default_gw="$(printf '%s\n' "$default_route" | ${pkgs.gnugrep}/bin/grep -oE 'via [^ ]+' | ${pkgs.coreutils}/bin/cut -d' ' -f2 || true)"
                                              default_dev="$(printf '%s\n' "$default_route" | ${pkgs.gnugrep}/bin/grep -oE 'dev [^ ]+' | ${pkgs.coreutils}/bin/cut -d' ' -f2 || true)"

                                              if [ -n "$default_dev" ]; then
                                                if [ -n "$default_gw" ]; then
                                                  ${pkgs.iproute2}/bin/ip route replace "$VPNGATEWAY/32" via "$default_gw" dev "$default_dev"
                                                else
                                                  ${pkgs.iproute2}/bin/ip route replace "$VPNGATEWAY/32" dev "$default_dev"
                                                fi
                                              fi
                                            }

                                            apply_split_routes() {
                                              i=0
                                              while [ "$i" -lt "''${CISCO_SPLIT_INC:-0}" ]; do
                                                route_addr="$(${pkgs.coreutils}/bin/printenv "CISCO_SPLIT_INC_''${i}_ADDR" || true)"
                                                route_mask="$(${pkgs.coreutils}/bin/printenv "CISCO_SPLIT_INC_''${i}_MASK" || true)"
                                                if [ -n "$route_addr" ] && [ -n "$route_mask" ]; then
                                                  if route_prefix="$(mask_to_prefix "$route_mask")"; then
                                                    ${pkgs.iproute2}/bin/ip route replace "$route_addr/$route_prefix" dev "$IFACE"
                                                  fi
                                                fi
                                                i=$((i + 1))
                                              done
                                            }

                                            IFACE="''${TUNDEV:-''${TUNSETIFF:-${vpnInterface}}}"
                                            PREFIX="''${INTERNAL_IP4_NETMASKLEN:-}"
                                            DNS_SERVERS="''${INTERNAL_IP4_DNS:-${campusDnsFallback}}"
                                            TUN_MTU="''${INTERNAL_IP4_MTU:-1100}"

                                            if [ -z "$PREFIX" ] && [ -n "$INTERNAL_IP4_NETMASK" ]; then
                                              PREFIX="$(mask_to_prefix "$INTERNAL_IP4_NETMASK")"
                                            fi
                                            PREFIX="''${PREFIX:-24}"

                                            echo "$(date): VPN script started"
                                            echo "reason=$reason"
                                            echo "INTERNAL_IP4_ADDRESS=$INTERNAL_IP4_ADDRESS"
                                            echo "TUNDEV=$TUNDEV"
                                            echo "TUNSETIFF=$TUNSETIFF"
                                            echo "IFACE=$IFACE"
                                            echo "PREFIX=$PREFIX"

                                            case "$reason" in
                                              connect)
                                                if [ -z "$INTERNAL_IP4_ADDRESS" ]; then
                                                  echo "INTERNAL_IP4_ADDRESS is empty"
                                                  exit 1
                                                fi

                                                echo "Setting up interface $IFACE with $INTERNAL_IP4_ADDRESS/$PREFIX"
                                                ${pkgs.iproute2}/bin/ip link set "$IFACE" mtu "$TUN_MTU" up
                                                ${pkgs.iproute2}/bin/ip addr replace "$INTERNAL_IP4_ADDRESS/$PREFIX" dev "$IFACE"

                                                ensure_gateway_route
                                                apply_split_routes
                      ${staticCampusRouteCommands}
                                                ${pkgs.systemd}/bin/resolvectl dns "$IFACE" $DNS_SERVERS
                                                ${pkgs.systemd}/bin/resolvectl domain "$IFACE" ${campusDomainArgs}
                                                ${pkgs.systemd}/bin/resolvectl default-route "$IFACE" no
                                                ${pkgs.systemd}/bin/resolvectl flush-caches
                                                echo "Interface setup complete"
                                                ;;
                                              disconnect)
                                                echo "Disconnecting $IFACE"
                                                ${pkgs.systemd}/bin/resolvectl revert "$IFACE"
                                                ${pkgs.iproute2}/bin/ip link set "$IFACE" down
                                                ;;
                                            esac
                    ''}"

                    echo "$COOKIE" | sudo ${pkgs.openconnect}/bin/openconnect \
                      --protocol=gp \
                      --interface="${vpnInterface}" \
                      --user="$USER" \
                      --os="$OS" \
                      --mtu 1100 \
                      --no-dtls \
                      --passwd-on-stdin \
                      --csd-wrapper="${pkgs.openconnect}/libexec/openconnect/hipreport.sh" \
                      --script "$VPN_SCRIPT" \
                      ${openconnectUrl}
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
