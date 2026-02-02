{
  lib,
  mkForEachUsers,
  ...
}:
{
  options.users.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.custom.desktop.apps.bottles.enable = lib.mkEnableOption "Bottles";
      }
    );
  };

  config = {
    home-manager.users = mkForEachUsers (user: user.custom.desktop.apps.bottles.enable) (
      _:
      { pkgs, ... }:
      {
        home.packages = [ (pkgs.bottles.override { removeWarningPopup = true; }) ];
        home.persistence."/persist".directories = [
          ".local/share/bottles"
        ];
      }
    );
  };
}
