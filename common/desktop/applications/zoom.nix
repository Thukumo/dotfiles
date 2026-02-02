{
  lib,
  mkForEachUsers,
  ...
}:

{
  options.users.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.custom.desktop.apps.zoom.enable = lib.mkEnableOption "Zoom";
      }
    );
  };

  config.home-manager.users = mkForEachUsers (user: user.custom.desktop.apps.zoom.enable) (
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
