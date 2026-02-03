{
  lib,
  mkForEachUsers,
  config,
  ...
}:
{
  options.custom.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.desktop.apps.qutebrowser.enable = lib.mkEnableOption "qutebrowser";
      }
    );
  };

  config = {
    home-manager.users = mkForEachUsers (user: config.custom.users.${user.name}.desktop.apps.qutebrowser.enable) (_: {
      programs.qutebrowser = {
        enable = true;
        settings.tabs.position = "left";
      };
      home.persistence."/persist".directories = [
      ];
    });
  };
}
