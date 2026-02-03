{
  lib,
  myLib,
  config,
  ...
}:
{
  options.custom.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.desktop.apps.mattermost-desktop.enable = lib.mkEnableOption "Mattermost Desktop";
      }
    );
  };

  config = {
    home-manager.users = myLib.mkForEachUsers (user: config.custom.users.${user.name}.desktop.apps.mattermost-desktop.enable) (
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
