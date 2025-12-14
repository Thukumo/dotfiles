{ lib, config, ... }:

{
  options.custom.desktop = {
    type = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "niri" ]);
      default = "niri";
    };
  };
  imports = [
    ./greetd.nix
    ./niri
    ./applications
  ];

  config = lib.mkIf (config.custom.desktop.type != null) {

    environment.pathsToLink = [
      "/share/xdg-desktop-portal"
      "/share/applications"
    ];

    services.udisks2.enable = true;
    services.gvfs.enable = true;

    security.rtkit.enable = true;

    security.polkit.enable = true;

  };
}
