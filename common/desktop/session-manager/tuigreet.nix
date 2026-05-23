{
  lib,
  config,
  desktopLib,
  pkgs,
  ...
}:

{
  # options.custom.desktop = {
  #   defaultUser = lib.mkOption {
  #     type = lib.types.str;
  #   };
  # };
  config =
    lib.mkIf (config.custom.desktop.anyEnabled && config.custom.desktop.sessionManager == "tuigreet")
      {
        services.greetd = {
          enable = true;
          settings = {
            default_session.user = config.users.users."tsukumo".name;
            default_session.command = "${pkgs.tuigreet}/bin/tuigreet --time ${
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
