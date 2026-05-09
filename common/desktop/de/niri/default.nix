{
  lib,
  config,
  myLib,
  ...
}:

{
  config = {
    services.greetd.settings =
      lib.mkIf
        (
          config.custom.desktop.anyEnabled
          && (lib.any (u: u.desktop.de == "niri") (lib.attrValues config.custom.users))
        )
        {
          default_session.command = "niri-session";
          initial_session.command = "niri-session";
        };

    home-manager.users = myLib.mkForEachUsers (user: user.custom.desktop.de or null == "niri") (_: {
      imports = [
        ./home.nix
      ];
    });
  };
}
