{
  lib,
  config,
  desktopLib,
  pkgs,
  ...
}:
{
  config =
    lib.mkIf
      (builtins.any (user: user.desktop.apps.slack.enable) (builtins.attrValues config.custom.users))
      {
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
