{
  lib,
  myLib,
  ...
}:
{
  options.custom.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (_: {
        options.network.sstp = {
          enable = lib.mkEnableOption "SSTP VPN";
          vpnServer = lib.mkOption {
            type = lib.types.str;
            default = "srasvpn.sic.shibaura-it.ac.jp";
          };
          dnsDomains = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [
              "shibaura-it.ac.jp"
            ];
          };
        };
      })
    );
  };

  config.home-manager.users = myLib.mkForEachUsers (user: user.custom.network.sstp.enable or false) (
    user:
    { pkgs, osConfig, ... }:
    let
      cfg = user.custom.network.sstp;
      vpnInterface = "ppp0"; # SSTPは通常pppインターフェース
      secretPath = osConfig.age.secrets."sras-vpn".path;

      # resolvectl用のドメイン引数生成 (~domain はそのドメインのみ解決に使用する)
      dnsDomains = map (domain: if lib.hasPrefix "~" domain then domain else "~${domain}") cfg.dnsDomains;
      domainArgs = lib.concatStringsSep " " (map lib.escapeShellArg dnsDomains);

      dnsScript = pkgs.writeShellScript "sras-vpn-dns.sh" ''
        set -euo pipefail
        IFACE="${vpnInterface}"
        echo "Configuring DNS for SIT domains on $IFACE..."
        ${pkgs.systemd}/bin/resolvectl domain "$IFACE" ${domainArgs}
        ${pkgs.systemd}/bin/resolvectl default-route "$IFACE" no
        ${pkgs.systemd}/bin/resolvectl flush-caches
        echo "DNS configured."
      '';
    in
    {
      home.packages = [
        (pkgs.writeShellScriptBin "vpn-sstp-connect" ''
          set -euo pipefail

          # すでに接続されているか確認
          if ip addr show "${vpnInterface}" > /dev/null 2>&1; then
            echo "Error: VPN interface ${vpnInterface} already exists. Is VPN already running?"
            exit 1
          fi

          # シークレットファイルを安全に読み込む
          if [ -f "${secretPath}" ]; then
            eval "$(sudo cat "${secretPath}")"
          else
            echo "Error: Secret file ${secretPath} not found."
            exit 1
          fi

          # CRLF混入対策（MS-CHAPv2失敗の原因になる）
          SRAS_USERNAME="''${SRAS_USERNAME%$'\r'}"
          SRAS_PASSWORD="''${SRAS_PASSWORD%$'\r'}"

          if [ -z "''${SRAS_USERNAME:-}" ] || [ -z "''${SRAS_PASSWORD:-}" ]; then
            echo "Error: SRAS_USERNAME or SRAS_PASSWORD is not set in the secret file."
            exit 1
          fi

          echo "Connecting to SSTP VPN at ${cfg.vpnServer}..."

          auth_username="$SRAS_USERNAME"
          echo "Using username from secret file."

          # DNS設定を待機して実行するバックグラウンドプロセス
          (
            while ! ip addr show "${vpnInterface}" > /dev/null 2>&1; do
              sleep 1
              if ! pgrep -f "sstpc.*${cfg.vpnServer}" > /dev/null; then exit 0; fi
            done
            sudo ${dnsScript}
          ) &

          # sstpc は pppd を起動するため、sudo 権限が必要
          sudo ${pkgs.sstp}/bin/sstpc \
            --log-stderr \
            --log-level 4 \
            --user "$auth_username" \
            --password "$SRAS_PASSWORD" \
            --cert-warn \
            --tls-ext \
            "${cfg.vpnServer}" \
            -- \
            nodetach \
            debug \
            dump \
            logfd 2 \
            noauth \
            refuse-pap \
            refuse-chap \
            refuse-mschap \
            refuse-eap \
            require-mppe-128 \
            user "$auth_username" \
            password "$SRAS_PASSWORD" \
            remotename "${cfg.vpnServer}" \
            ipparam vpn-sstp \
            nodefaultroute \
            lcp-echo-interval 0
        '')
      ];
    }
  );
}
