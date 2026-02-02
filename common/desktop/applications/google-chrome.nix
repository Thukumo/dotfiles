{
  lib,
  mkForEachUsers,
  ...
}:
{
  options.users.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.custom.desktop.apps.google-chrome.enable = lib.mkEnableOption "Google Chrome";
      }
    );
  };

  config = {
    home-manager.users = mkForEachUsers (user: user.custom.desktop.apps.google-chrome.enable) (
      _:
      { pkgs, ... }:
      {
        home.packages = [ pkgs.google-chrome ];
        home.persistence."/persist".directories = [
          ".config/google-chrome"
        ];
      }
    );
  };
}
