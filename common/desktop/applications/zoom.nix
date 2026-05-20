{
  lib,
  desktopLib,
  ...
}:

{
  options.custom.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.desktop.apps.zoom.enable = lib.mkEnableOption "Zoom";
      }
    );
  };

  config.home-manager.users =
    desktopLib.mkHome (user: user.custom.desktop.apps.zoom.enable or false)
      (
        _:
        { pkgs, ... }:
        {
          home.packages = with pkgs; [
            zoom-us
          ];
          home.persistence."/persist" = {
            directories = [
              ".zoom"
              ".cache/zoom"
            ];
            files = [
              ".config/zoom.conf"
              ".config/zoomus.conf"
            ];
          };
        }
      );
}
