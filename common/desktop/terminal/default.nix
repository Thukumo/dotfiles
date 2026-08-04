{ lib, myLib, ... }:
{
  options.custom.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.desktop.terminal = lib.mkOption {
          type = lib.types.nullOr (lib.types.enum [ "foot" ]);
          default = null;
          description = "Terminal emulator to use";
        };
      }
    );
  };

  imports = myLib.mkImportModuleFiles ./.;
}
