{
  lib,
  mkForEachUsers,
  pkgs,
  ...
}:
{
  options.users.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        {
          options.custom.desktop.apps.qutebrowser.enable = lib.mkEnableOption "qutebrowser";
        }
      )
    );
  };

  config = {
    home-manager.users = mkForEachUsers (user: user.custom.desktop.apps.qutebrowser.enable) (
      user:
      { config, ... }:
      {
        programs.qutebrowser = {
          enable = true;
          settings.tabs.position = "left";
        };
        home.persistence."/persist".directories = [
        ];
      }
    );
  };
}
