{
  lib,
  mkForEachUsers,
  config,
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

  config.home-manager.users = mkForEachUsers (user: config.custom.users.${user.name}.desktop.apps.zoom.enable or false) (
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
