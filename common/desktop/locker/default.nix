{ lib, myLib, ... }:
{
  options.custom.users = myLib.mkUserOption {
    options.desktop.locker = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "hyprlock"
          "swaylock"
        ]
      );
      default = "swaylock";
      description = "Screen locker to use";
    };
  };

  imports = myLib.mkImportModuleFiles ./.;
}
