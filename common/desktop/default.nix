{
  lib,
  myLib,
  ...
}:

{
  options.custom.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.desktop = {
          enable = lib.mkEnableOption "desktop environment";

          de = lib.mkOption {
            type = lib.types.nullOr (
              lib.types.enum [
                "niri"
                "gnome"
              ]
            );
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

          activate-linux.enable = lib.mkEnableOption "activate-linux watermark";
        };
      }
    );
  };

  options.custom.desktop = {
    sunshine.enable = lib.mkEnableOption "";
    pipewire.enable = myLib.mkEnabledOption;
  };

  imports =
    let
      # Import all subdirectories
      dirs = lib.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./.));
      # Import all .nix files except default.nix
      files = lib.attrNames (
        lib.filterAttrs (
          name: type: type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix"
        ) (builtins.readDir ./.)
      );
    in
    (map (name: ./. + "/${name}") dirs) ++ (map (name: ./. + "/${name}") files);

  config = {
    environment.pathsToLink = [
      "/share/xdg-desktop-portal"
      "/share/applications"
    ];

    services.udisks2.enable = true;
    services.gvfs.enable = true;

    security.polkit.enable = true;
  };
}
