{
  myLib,
  config,
  ...
}:

{
  config = {
    programs.niri.enable = true;

    services.greetd.settings = {
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
