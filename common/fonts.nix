{ pkgs, ... }:

{
  fonts.packages = with pkgs; [
    nerd-fonts.adwaita-mono
    ipafont
  ];
}
