{ lib, myLib, ... }:
{
  options.custom.users = myLib.mkUserOption {
    options.desktop.panel = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "quickshell" ]);
      default = "quickshell";
      description = "On-demand widget panel (Win+A) to use";
    };
  };

  imports = myLib.mkImportModuleFiles ./.;
}
