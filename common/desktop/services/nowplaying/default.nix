{
  lib,
  myLib,
  desktopLib,
  inputs,
  ...
}:

{
  options.custom.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.desktop.nowplaying = {
          enable = myLib.mkEnabledOption;
          server = lib.mkOption {
            type = lib.types.str;
            default = "https://api-nowplaying.tsukumo.f5.si";
            description = "Base URL of the nowplaying server (Cloudflare Tunnel on mouse-3).";
          };
        };
      }
    );
  };

  config.home-manager.users = desktopLib.mkHome (user: user.custom.desktop.nowplaying.enable) (
    user:
    { pkgs, ... }:
    let
      cfg = user.custom.desktop.nowplaying;
      client = inputs.nowplaying.packages.${pkgs.stdenv.hostPlatform.system}.client;
    in
    {
      age.secrets."nowplaying_token".file = ./nowplaying-token.age;

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
}
