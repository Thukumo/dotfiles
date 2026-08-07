{ lib, myLib, ... }:
{
  options.custom.users = myLib.mkUserOption {
    options.desktop.de = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "niri" ]);
      default = null;
      description = "Desktop environment or window manager to use";
    };
  };

  imports = myLib.mkImportSubdirs ./.;
}
