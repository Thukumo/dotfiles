{ lib, myLib, ... }:
{
  options.custom.users = myLib.mkUserOption {
    options.desktop = {
      hyprlock.enable = myLib.mkEnabledOption;
      activate-linux.enable = lib.mkEnableOption "activate-linux watermark";
    };
  };

  imports = myLib.mkImportModules ./. [ ];
}
