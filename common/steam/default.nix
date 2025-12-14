{ config, lib, ... }:

{
  options.tsukumo.desktop.steam.enable = lib.mkEnableOption "Steam";
  config = lib.mkIf config.tsukumo.desktop.steam.enable {
    hardware.graphics.enable32Bit = true;
    programs.steam.enable = true;
    home-manager.users."tsukumo".imports = [
      ./persistence.nix
    ];
  };
}
