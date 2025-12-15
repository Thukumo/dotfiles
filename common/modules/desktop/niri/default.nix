{ lib, config, ... }:

{
  config = lib.mkIf (config.custom.desktop.type == "niri") {
    services.greetd = {
      settings = rec {
        default_session.command = "${
          config.home-manager.users."tsukumo".programs.niri.package
        }/bin/niri-session";
        initial_session.command = default_session.command;
      };
    };
    home-manager.users."tsukumo" =
      { ... }:
      {
        imports = [
          ./home-niri.nix
        ];
        home.sessionVariables = {
          ELECTRON_OZONE_PLATFORM_HINT = "wayland";
        };
      };
  };
}
