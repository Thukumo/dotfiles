{
  lib,
  config,
  desktopLib,
  ...
}:

{
  config = {
    custom.desktop.sessionCommand = lib.mkIf (
      config.custom.desktop.anyEnabled
      && (lib.any (u: u.desktop.enable && u.desktop.de == "niri") (lib.attrValues config.custom.users))
    ) "niri-session";

    home-manager.users = desktopLib.mkHome (user: user.custom.desktop.de or null == "niri") (_: {
      imports = [
        ./home.nix
      ];
    });
  };
}
