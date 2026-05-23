{
  lib,
  config,
  desktopLib,
  ...
}:

{
  # options.custom.desktop = {
  #   defaultUser = lib.mkOption {
  #     type = lib.types.str;
  #   };
  # };
  config =
    lib.mkIf (config.custom.desktop.anyEnabled && config.custom.desktop.sessionManager == "greetd")
      {
        services.greetd = {
          enable = true;
          settings = {
            default_session.user = config.users.users."tsukumo".name;
            initial_session.user = config.users.users."tsukumo".name;
          };
        };
        security.pam.services.greetd.enableGnomeKeyring = true;
        home-manager.users = desktopLib.mkHome (_: true) (_user: {
          home.persistence."/persist".directories = [
            ".local/share/keyrings"
          ];
        });
      };
}
