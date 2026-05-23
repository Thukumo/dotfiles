{
  desktopLib,
  ...
}:
{
  config = {
    home-manager.users = desktopLib.mkHome (user: user.custom.desktop.apps.mattermost-desktop.enable) (
      _:
      { config, pkgs, ... }:
      {
        home.packages = [ pkgs.mattermost-desktop ];
        # Mattermost Desktopが~/.config/autostart/electron.desktopを作ってきて困るので、
        # 先に/dev/nullへのシンボリックリンクにしておく
        xdg.configFile."autostart/electron.desktop".source =
          config.lib.file.mkOutOfStoreSymlink "/dev/null";
        home.persistence."/persist".directories = [
          ".config/Mattermost"
        ];
        home.sessionVariables = {
          ELECTRON_OZONE_PLATFORM_HINT = "auto";
        };
      }
    );
  };
}
