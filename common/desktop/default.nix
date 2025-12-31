{
  lib,
  config,
  mkForEachUsers,
  ...
}:

{
  options.users.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.custom.desktop = {
          enable = lib.mkEnableOption "desktop environment";
          
          de = lib.mkOption {
            type = lib.types.nullOr (lib.types.enum [ "niri" "gnome" ]);
            default = null;
            description = "Desktop environment or window manager to use";
          };

          launcher = lib.mkOption {
            type = lib.types.nullOr (lib.types.enum [ "fuzzel" ]);
            default = null;
            description = "Application launcher to use";
          };

          terminal = lib.mkOption {
            type = lib.types.nullOr (lib.types.enum [ "foot" ]);
            default = null;
            description = "Terminal emulator to use";
          };

          ime = lib.mkOption {
            type = lib.types.nullOr (lib.types.enum [ "skk" ]);
            default = null;
            description = "Input method engine to use";
          };
        };
      }
    );
  };

  imports = [
    ./session-manager/greetd.nix
    ./de/niri
    ./de/gnome
    ./applications
    ./terminal/foot.nix
    ./launcher/fuzzel.nix
    ./ime/fcitx5.nix
  ];

  config = {
    environment.pathsToLink = [
      "/share/xdg-desktop-portal"
      "/share/applications"
    ];

    services.udisks2.enable = true;
    services.gvfs.enable = true;

    security.rtkit.enable = true;
    security.polkit.enable = true;

    home-manager.users = mkForEachUsers (user: user.custom.desktop.enable) (user: {
      services.mako = {
        enable = true;
        settings = {
          ignore-timeout = 1;
          default-timeout = 5000;
          max-visible = 10;
        };
      };
    });
  };
}
