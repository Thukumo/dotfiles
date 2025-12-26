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
          options.custom.util.flatpak.enable = lib.mkEnableOption "flatpak";
        }
      )
    );
  };

  config = {
    home-manager.users = mkForEachUsers (user: user.custom.desktop.apps.bottles.enable) (
      user:
      { config, ... }:
      {
        services.flatpak.enable = true;
        home.persistence."/persist${config.home.homeDirectory}".directories = [
          ".local/share/flatpak"
        ];
      }
    );
  };
}
