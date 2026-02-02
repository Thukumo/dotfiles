{
  lib,
  mkForEachUsers,
  ...
}:
{
  options.users.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.custom.desktop.apps.qutebrowser.enable = lib.mkEnableOption "qutebrowser";
      }
    );
  };

  config = {
    home-manager.users = mkForEachUsers (user: user.custom.desktop.apps.qutebrowser.enable) (_: {
      programs.qutebrowser = {
        enable = true;
        settings.tabs.position = "left";
      };
      home.persistence."/persist".directories = [
      ];
    });
  };
}
