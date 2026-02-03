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
        options.desktop.apps.discord.enable = lib.mkEnableOption "Discord";
      }
    );
  };

  config = {
    home-manager.users = myLib.mkForEachUsers (user: user.custom.desktop.apps.discord.enable or false) (
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
