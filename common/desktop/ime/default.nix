{ lib, myLib, ... }:
{
  options.custom.users = myLib.mkUserOption {
    options.desktop.ime = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "skk" ]);
      default = null;
      description = "Input method engine to use";
    };
  };

  imports = myLib.mkImportModuleFiles ./.;
}
