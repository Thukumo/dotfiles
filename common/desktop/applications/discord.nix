{
  lib,
  config,
  desktopLib,
  pkgs,
  ...
}:
{
  config =
    lib.mkIf
      (builtins.any (user: user.desktop.apps.discord.enable or false) (
        builtins.attrValues config.custom.users
      ))
      {
        nixpkgs.config.allowUnfreePackages = [ pkgs.discord.pname ];
        home-manager.users = desktopLib.mkHome (user: user.custom.desktop.apps.discord.enable or false) (
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
