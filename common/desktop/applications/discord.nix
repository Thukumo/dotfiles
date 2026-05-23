{
  desktopLib,
  ...
}:
{
  config = {
    home-manager.users = desktopLib.mkHome (user: user.custom.desktop.apps.discord.enable or false) (
      _:
      { pkgs, ... }:
      {
        home.packages = [ pkgs.discord ];
        home.persistence."/persist".directories = [
          ".config/discord"
        ];
        home.sessionVariables = {
          ELECTRON_OZONE_PLATFORM_HINT = "auto";
        };
      }
    );
  };
}
