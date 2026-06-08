{
  desktopLib,
  ...
}:
{
  config = {
    home-manager.users = desktopLib.mkHome (user: user.custom.desktop.apps.osu.enable or false) (
      _:
      { pkgs, ... }:
      {
        home.packages = [ pkgs.osu-lazer-bin ];
        home.persistence."/persist".directories = [
          ".local/share/osu"
        ];
      }
    );
  };
}
