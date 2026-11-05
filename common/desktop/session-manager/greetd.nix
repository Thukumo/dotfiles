{
  lib,
  config,
  desktopLib,
  ...
}:

{
  config =
    lib.mkIf (config.custom.desktop.anyEnabled && config.custom.desktop.sessionManager == "greetd")
      {
        services.greetd = {
          enable = true;
          settings = {
            default_session.user = config.custom.defaultUser;
            default_session.command = config.custom.desktop.sessionCommand;
            initial_session.user = config.custom.defaultUser;
            initial_session.command = config.custom.desktop.sessionCommand;
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
