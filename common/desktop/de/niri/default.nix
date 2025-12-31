{
  lib,
  config,
  mkForEachUsers,
  ...
}:

{
  config = {
    programs.niri.enable = true;
    
    services.greetd.settings = {
      default_session.command = "niri-session";
      initial_session.command = "niri-session";
    };

    home-manager.users = mkForEachUsers (user: user.custom.desktop.de == "niri") (user: {
      imports = [
        ./home.nix
      ];
    });
  };
}
