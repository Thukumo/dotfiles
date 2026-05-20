{
  lib,
  desktopLib,
  ...
}:
{
  options.custom.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.desktop.apps.slack.enable = lib.mkEnableOption "Slack";
      }
    );
  };

  config = {
    home-manager.users = desktopLib.mkHome (user: user.custom.desktop.apps.slack.enable or false) (
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
