{
  lib,
  mkForEachUsers,
  ...
}:
{
  options.users.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.custom.desktop.apps.prismLauncher.enable = lib.mkEnableOption "Discord";
      }
    );
  };

  config = {
    home-manager.users = mkForEachUsers (user: user.custom.desktop.apps.prismLauncher.enable) (
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
