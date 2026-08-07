{
  lib,
  config,
  desktopLib,
  myLib,
  pkgs,
  ...
}:
{
  config = lib.mkIf (myLib.anyUser config (user: user.desktop.apps.discord.enable)) {
    nixpkgs.config.allowUnfreePackages = [ pkgs.discord.pname ];
    home-manager.users = desktopLib.mkHome (user: user.custom.desktop.apps.discord.enable) (
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
