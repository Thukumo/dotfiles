{
  lib,
  config,
  desktopLib,
  myLib,
  pkgs,
  ...
}:
{
  config = lib.mkIf (myLib.anyUser config (user: user.desktop.apps.osu.enable)) {
    nixpkgs.config.allowUnfreePackages = [ pkgs.osu-lazer-bin.pname ];
    home-manager.users = desktopLib.mkHome (user: user.custom.desktop.apps.osu.enable) (
      _:
      { pkgs, ... }:
      {
        home.packages = [ pkgs.osu-lazer-bin ];
        home.persistence."/persist".directories = [
          ".local/share/osu"
        ];
      }
    );
  };
}
