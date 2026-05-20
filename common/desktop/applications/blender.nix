{
  lib,
  desktopLib,
  ...
}:
{
  options.custom.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.desktop.apps.blender.enable = lib.mkEnableOption "Blender";
      }
    );
  };

  config = {
    home-manager.users = desktopLib.mkHome (user: user.custom.desktop.apps.blender.enable or false) (
      _:
      { pkgs, ... }:
      {
        home.packages = [ pkgs.blender ];
      }
    );
  };
}
