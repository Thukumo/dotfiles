{ config, myLib, ... }:

{
  # options.custom.desktop = {
  #   defaultUser = lib.mkOption {
  #     type = lib.types.str;
  #   };
  # };
  config = {
    services.greetd = {
      enable = true;
      settings = {
        default_session.user = config.users.users."tsukumo".name;
        initial_session.user = config.users.users."tsukumo".name;
      };
    };
    security.pam.services.greetd.enableGnomeKeyring = true;
    home-manager.users = myLib.mkForEachUsers (_: true) (user: {
      home.persistence."/persist".directories = [
        ".local/share/keyrings"
      ];
    });
  };
}
