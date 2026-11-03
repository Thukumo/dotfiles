{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.custom.network.cloudflare-warp;

  excludeRoutes = pkgs.writeShellApplication {
    name = "cloudflare-warp-exclude-routes";
    runtimeInputs = [
      pkgs.coreutils
      config.services.cloudflare-warp.package
    ];
    text = ''
      # add-range is idempotent; retry only until warp-svc accepts commands.
      for _ in $(seq 1 30); do
        if ${
          lib.concatMapStringsSep " && " (
            range: "warp-cli --accept-tos tunnel ip add-range ${lib.escapeShellArg range} >/dev/null"
          ) cfg.excludeRoutes
        }; then
          exit 0
        fi
        sleep 1
      done
      echo "failed to add WARP split-tunnel exclusions: ${lib.concatStringsSep " " cfg.excludeRoutes}" >&2
      exit 1
    '';
  };
in
{
  options.custom.network.cloudflare-warp = {
    enable = lib.mkEnableOption "Cloudflare Warp";

    excludeRoutes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "IP ranges to exclude from the WARP tunnel (split tunnel).";
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.config.allowUnfreePackages = [ pkgs.cloudflare-warp.pname ];
    services.cloudflare-warp.enable = true;
    environment.persistence."/persist".directories = [ "/var/lib/cloudflare-warp" ];

    systemd.services.cloudflare-warp-split-tunnel = lib.mkIf (cfg.excludeRoutes != [ ]) {
      description = "Apply Cloudflare WARP split-tunnel exclusions";
      wantedBy = [ "multi-user.target" ];
      requires = [ "cloudflare-warp.service" ];
      after = [ "cloudflare-warp.service" ];
      partOf = [ "cloudflare-warp.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = excludeRoutes;
      };
    };
  };
}
