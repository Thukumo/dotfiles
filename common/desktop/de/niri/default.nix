{
  lib,
  config,
  desktopLib,
  ...
}:

{
  config =
    lib.mkIf
      (
        config.custom.desktop.anyEnabled
        && (lib.any (u: u.desktop.enable && u.desktop.de == "niri") (lib.attrValues config.custom.users))
      )
      {
        custom.desktop.sessionCommand = "niri-session";

        nix.settings = {
          substituters = [ "https://niri.cachix.org" ];
          trusted-public-keys = [
            "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
          ];
        };

        home-manager.users = desktopLib.mkHome (user: user.custom.desktop.de or null == "niri") (_: {
          imports = [
            ./home.nix
          ];
        });
      };
}
