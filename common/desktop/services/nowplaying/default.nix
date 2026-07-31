{
  lib,
  myLib,
  desktopLib,
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
            default = "http://mouse-3:8181";
            description = "Base URL of the nowplaying server. mouse-3 resolves via const/mycelium (networking.hosts).";
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
      runtimePath = lib.makeBinPath (
        with pkgs;
        [
          playerctl
          jq
          curl
          coreutils
        ]
      );
    in
    {
      home.packages = with pkgs; [
        playerctl
        jq
      ];

      age.secrets."nowplaying_token".file = ./nowplaying-token.age;

      systemd.user.services.nowplaying-bridge = {
        Unit.Description = "MPRIS to nowplaying server bridge";
        Service = {
          ExecStart = "${pkgs.bash}/bin/bash ${./bridge.sh}";
          Environment = [
            "NOWPLAYING_SERVER=${cfg.server}"
            # agenix default secret location, %t expands to $XDG_RUNTIME_DIR
            "NOWPLAYING_TOKEN_FILE=%t/agenix/nowplaying_token"
            "PATH=${runtimePath}"
          ];
          Restart = "on-failure";
          RestartSec = "5";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    }
  );
}
