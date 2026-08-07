{ lib, myLib, ... }:
{
  options.custom.users = myLib.mkUserOption {
    options.desktop.terminal = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "foot" ]);
      default = null;
      description = "Terminal emulator to use";
    };
  };

  imports = myLib.mkImportModuleFiles ./.;
}
