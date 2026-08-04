{ lib, myLib, ... }:
{
  options.custom.desktop = {
    sessionManager = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "greetd"
          "tuigreet"
        ]
      );
      default = "tuigreet";
      description = "Session manager to use";
    };

    sessionCommand = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      internal = true;
      description = "Command to start the desktop session";
    };
  };

  imports = myLib.mkImportModuleFiles ./.;
}
