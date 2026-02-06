{
  myLib,
  ...
}:

{
  config = {
    # Note: programs.niri.enable is always enabled to avoid infinite recursion
    # when checking custom.users (similar issue to avahi creating system users)
    # The actual niri usage is controlled by home-manager imports below
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
