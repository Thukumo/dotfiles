{
  lib,
  config,
  myLib,
  ...
}:

{
  options.custom.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        {
          options.desktop = {
            enable = lib.mkEnableOption "desktop environment";
            vr = {
              enable = lib.mkEnableOption "VR support";
              immersed.enable = lib.mkOption {
                type = lib.types.bool;
                default = config.desktop.vr.enable;
              };
            };
          };
        }
      )
    );
  };

  options.custom.desktop = {
    sunshine.enable = lib.mkEnableOption "";
    pipewire.enable = myLib.mkEnabledOption;
    anyEnabled = lib.mkOption {
      type = lib.types.bool;
      internal = true;
      default = lib.any (u: u.desktop.enable) (lib.attrValues config.custom.users);
      description = "Whether any user has desktop enabled";
    };
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

  config = lib.mkMerge [
    {
      _module.args.desktopLib = {
        mkHome =
          condition: content:
          myLib.mkForEachUsers (user: user.custom.desktop.enable && (condition user)) content;
      };
      home-manager.users = myLib.mkForEachUsers (user: user.custom.desktop.enable) (
        _user:
        { lib, config, ... }:
        {
          options.custom.desktop.persistDesktopEntries = lib.mkEnableOption "persistence for ~/.local/share/applications (Desktop Entries)";

          config = lib.mkIf config.custom.desktop.persistDesktopEntries {
            home.persistence."/persist".directories = [
              ".local/share/applications"
            ];
          };
        }
      );
    }
    (lib.mkIf config.custom.desktop.anyEnabled {
      environment.pathsToLink = [
        "/share/xdg-desktop-portal"
        "/share/applications"
      ];

      services.udisks2.enable = true;
      services.gvfs.enable = true;

      security.polkit.enable = true;
    })
  ];
}
