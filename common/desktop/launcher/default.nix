{ lib, myLib, ... }:
{
  options.custom.users = myLib.mkUserOption {
    options.desktop.launcher = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "fuzzel" ]);
      default = null;
      description = "Application launcher to use";
    };
  };

  imports = myLib.mkImportModuleFiles ./.;
}
