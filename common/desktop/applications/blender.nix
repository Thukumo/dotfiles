{
  desktopLib,
  ...
}:
{
  config = {
    home-manager.users = desktopLib.mkHome (user: user.custom.desktop.apps.blender.enable) (
      _:
      { pkgs, ... }:
      {
        home.packages = [ pkgs.blender ];
      }
    );
  };
}
