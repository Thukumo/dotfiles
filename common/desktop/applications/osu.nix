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
      (builtins.any (user: user.desktop.apps.osu.enable) (builtins.attrValues config.custom.users))
      {
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
