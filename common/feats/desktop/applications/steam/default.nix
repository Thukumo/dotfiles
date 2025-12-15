{ config, lib, ... }:

{
  options.custom.desktop.apps.steam = {
    enable = lib.mkEnableOption "Steam";
  };
  config = lib.mkIf config.custom.desktop.apps.steam.enable {
    hardware.graphics.enable32Bit = true;
    programs.steam.enable = true;
    home-manager.users."tsukumo".imports = [
      ./home-persistence.nix
    ];
  };
}
