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
        options.desktop.apps.prismLauncher.enable = lib.mkEnableOption "Discord";
      }
    );
  };

  config = {
    home-manager.users = myLib.mkForEachUsers (user: user.custom.desktop.apps.prismLauncher.enable) (
      _:
      { pkgs, ... }:
      {
        home.packages = [ pkgs.prismlauncher ];
        home.persistence."/persist".directories = [
          ".local/share/prismlauncher"
        ];
      }
    );
  };
}
