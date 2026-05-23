{
  desktopLib,
  ...
}:
{
  config = {
    home-manager.users = desktopLib.mkHome (user: user.custom.desktop.apps.bottles.enable) (
      _:
      { pkgs, ... }:
      {
        home.packages = [ (pkgs.bottles.override { removeWarningPopup = true; }) ];
        home.persistence."/persist".directories = [
          ".local/share/bottles"
        ];
      }
    );
  };
}
