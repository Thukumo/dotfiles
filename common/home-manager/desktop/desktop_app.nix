{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    discord
    google-chrome
    libreoffice-still
    zoom-us
    gnome-disk-utility
    rquickshare
  ];
  home.persistence."/persist/${config.home.homeDirectory}".directories = [
    ".config/google-chrome"
    ".config/discord"
  ];
}
