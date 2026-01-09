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
          options.custom.desktop.apps.discord.enable = lib.mkEnableOption "Discord";
        }
      )
    );
  };

  config = {
    home-manager.users = mkForEachUsers (user: user.custom.desktop.apps.discord.enable) (
      user:
      { config, ... }:
      {
        home.packages = [ pkgs.discord ];
        home.persistence."/persist".directories = [
          ".config/discord"
        ];
        home.sessionVariables = {
          ELECTRON_OZONE_PLATFORM_HINT = "auto";
        };
      }
    );
  };
}
