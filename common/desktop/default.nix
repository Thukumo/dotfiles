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
      default = false;
      description = "Whether any user has desktop enabled";
    };
  };

  imports = myLib.mkImportModules ./. [ ];

  config = lib.mkMerge [
    {
      custom.desktop.anyEnabled = lib.mkDefault (
        lib.any (u: u.desktop.enable) (lib.attrValues config.custom.users)
      );

      _module.args.desktopLib = {
        mkHome =
          condition: content:
          myLib.mkForEachUsers config (user: user.custom.desktop.enable && (condition user)) content;
      };
      home-manager.users = myLib.mkForEachUsers config (user: user.custom.desktop.enable) (
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
