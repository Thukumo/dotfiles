{
  lib,
  mkForEachUsers,
  ...
}:
{
  options.users.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        {
          options.custom.desktop.apps.bottles.enable = lib.mkEnableOption "Bottles";
        }
      )
    );
  };

  config = {
    home-manager.users = mkForEachUsers (user: user.custom.desktop.apps.bottles.enable) (
      user:
      { pkgs, config, ... }:
      {
        home.packages = [ (pkgs.bottles.override { removeWarningPopup = true; }) ];
        home.persistence."/persist${config.home.homeDirectory}".directories = [
          ".local/share/bottles"
        ];
      }
    );
  };
}
