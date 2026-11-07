{
  lib,
  myLib,
  desktopLib,
  inputs,
  config,
  ...
}:

{
  options.custom.users = myLib.mkUserOption {
    options.desktop.nowplaying = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.submodule {
          options.server = lib.mkOption {
            type = lib.types.str;
            default = "https://api-nowplaying.tsukumo.f5.si";
            description = "Base URL of the nowplaying server (Cloudflare Tunnel on mouse-3).";
          };
        }
      );
      default = { };
      description = "Nowplaying bridge. Set to null to disable.";
    };
  };

  config = {
    custom.secrets.access.home = lib.mapAttrs (
      _: user:
      if user.desktop.enable && user.desktop.nowplaying != null then
        {
          nowplaying_token = {
            file = ./nowplaying-token.age;
            acceptedRisk = "home secret; user-level (AppArmor not used)";
            consumers = [ "nowplaying-bridge" ];
          };
        }
      else
        { }
    ) config.custom.users;

    home-manager.users = desktopLib.mkHome (user: user.custom.desktop.nowplaying != null) (
      user:
      { pkgs, ... }:
      let
        cfg = user.custom.desktop.nowplaying;
        client = inputs.nowplaying.packages.${pkgs.stdenv.hostPlatform.system}.client;
      in
      {
        systemd.user.services.nowplaying-bridge = {
          Unit.Description = "MPRIS to nowplaying server bridge";
          Service = {
            ExecStart = "${client}/bin/nowplaying-client";
            EnvironmentFile = [ "%t/agenix/nowplaying_token" ];
            Environment = [ "NOWPLAYING_SERVER=${cfg.server}" ];
            Restart = "on-failure";
            RestartSec = "5";
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };
      }
    );
  };
}
