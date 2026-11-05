{
  lib,
  config,
  desktopLib,
  pkgs,
  ...
}:

{
  config =
    lib.mkIf (config.custom.desktop.anyEnabled && config.custom.desktop.sessionManager == "tuigreet")
      {
        services.greetd = {
          enable = true;
          settings = {
            default_session.user = config.custom.defaultUser;
            default_session.command = "${pkgs.tuigreet}/bin/tuigreet --time --user-menu ${
              lib.optionalString (
                config.custom.desktop.sessionCommand != null
              ) "--cmd ${config.custom.desktop.sessionCommand}"
            }";
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
