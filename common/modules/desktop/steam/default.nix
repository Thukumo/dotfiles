{ config, lib, ... }:

{
  options.custom.desktop.steam = {
    enable = lib.mkEnableOption "Steam";
  };
  config = lib.mkIf config.custom.desktop.steam.enable {
    hardware.graphics.enable32Bit = true;
    programs.steam.enable = true;
    home-manager.users."tsukumo".imports = [
      ./home-persistence.nix
    ];
  };
}
