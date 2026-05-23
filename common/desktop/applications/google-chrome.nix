{
  desktopLib,
  ...
}:
{
  config = {
    home-manager.users = desktopLib.mkHome (user: user.custom.desktop.apps.google-chrome.enable) (
      _:
      { pkgs, ... }:
      {
        home.packages = [ pkgs.google-chrome ];
        home.persistence."/persist".directories = [
          ".config/google-chrome"
        ];
      }
    );
  };
}
