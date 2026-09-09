{ lib, myLib, ... }:
{
  options.custom.users = myLib.mkUserOption {
    options.desktop = {
      activate-linux.enable = lib.mkEnableOption "activate-linux watermark";
    };
  };

  imports = myLib.mkImportModules ./. [ ];
}
