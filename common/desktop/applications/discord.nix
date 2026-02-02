{
  lib,
  mkForEachUsers,
  ...
}:
{
  options.users.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.custom.desktop.apps.discord.enable = lib.mkEnableOption "Discord";
      }
    );
  };

  config = {
    home-manager.users = mkForEachUsers (user: user.custom.desktop.apps.discord.enable) (
      _:
      { pkgs, ... }:
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
