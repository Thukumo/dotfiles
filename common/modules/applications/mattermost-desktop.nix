{ lib, config, ... }:
{
  options.custom.apps.mattermost-desktop = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.custom.desktop.type != null;
    };
  };
  config = lib.mkIf config.custom.apps.mattermost-desktop.enable {
    home-manager.users."tsukumo" =
      { pkgs, config, ... }:
      {
        home.packages = [ pkgs.mattermost-desktop ];
        # Mattermost Desktopが~/.config/autostart/electron.desktopを作ってきて困るので、
        # 先に/dev/nullへのシンボリックリンクにしておく
        xdg.configFile."autostart/electron.desktop".source =
          config.lib.file.mkOutOfStoreSymlink "/dev/null";
        home.persistence."/persist/${config.home.homeDirectory}".directories = [
          ".config/Mattermost"
        ];
      };
  };
}
