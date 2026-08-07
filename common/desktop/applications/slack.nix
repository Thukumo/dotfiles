{
  lib,
  config,
  desktopLib,
  myLib,
  pkgs,
  ...
}:
{
  config = lib.mkIf (myLib.anyUser config (user: user.desktop.apps.slack.enable)) {
    nixpkgs.config.allowUnfreePackages = [ pkgs.slack.pname ];
    home-manager.users = desktopLib.mkHome (user: user.custom.desktop.apps.slack.enable) (
      _:
      { pkgs, ... }:
      {
        home.packages = [ pkgs.slack ];
        home.persistence."/persist".directories = [
          ".config/Slack"
        ];
      }
    );
  };
}
