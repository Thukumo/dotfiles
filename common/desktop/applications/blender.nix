{
  lib,
  myLib,
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
    home-manager.users = myLib.mkForEachUsers (user: user.custom.desktop.apps.blender.enable or false) (
      _:
      { pkgs, ... }:
      {
        home.packages = [ pkgs.blender ];
      }
    );
  };
}
