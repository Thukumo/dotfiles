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
          options.custom.desktop.apps.prismLauncher.enable = lib.mkEnableOption "Discord";
        }
      )
    );
  };

  config = {
    home-manager.users = mkForEachUsers (user: user.custom.desktop.apps.prismLauncher.enable) (
      user:
      { pkgs, config, ... }:
      {
        home.packages = [ pkgs.prismlauncher ];
        home.persistence."/persist".directories = [
          ".local/share/prismlauncher"
        ];
      }
    );
  };
}
