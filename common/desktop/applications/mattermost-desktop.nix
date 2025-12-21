{ lib, config, mkForEachUsers, pkgs, ... }:
{
  options.users.users = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options.custom.desktop.apps.mattermost-desktop = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
      };
    });
  };

  config = {
    home-manager.users = mkForEachUsers (user: user.custom.desktop.apps.mattermost-desktop.enable) (user: { config, ... }: {
      home.packages = [ pkgs.mattermost-desktop ];
      # Mattermost Desktopが~/.config/autostart/electron.desktopを作ってきて困るので、
      # 先に/dev/nullへのシンボリックリンクにしておく
      xdg.configFile."autostart/electron.desktop".source =
        config.lib.file.mkOutOfStoreSymlink "/dev/null";
      home.persistence."/persist${config.home.homeDirectory}".directories = [
        ".config/Mattermost"
      ];
    });
  };
}
