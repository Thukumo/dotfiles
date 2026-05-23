{
  desktopLib,
  ...
}:
{
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
