{
  pkgs,
  ...
}:

let
  wallpaper = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/Amog-OS/AmogOS-Wallpapers/ccec8fbc1d2ad18e4115bf6833f81e8ab774e6e9/Windows11-Blue.png";
    hash = "sha256-AoCAElNCj0bxgfMBcoqGaaHyByqto5RzqykP4aFyoRE=";
  };
in
{
  stylix = {
    enable = true;
    image = wallpaper;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/one-light.yaml";

    fonts = {
      serif = {
        package = pkgs.ipaexfont;
        name = "IPAexMincho";
      };

      sansSerif = {
        package = pkgs.ipaexfont;
        name = "IPAexGothic";
      };

      monospace = {
        package = pkgs.nerd-fonts.adwaita-mono;
        name = "Adwaita Mono Nerd Font";
      };

      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };

      sizes = {
        applications = 12;
        terminal = 14;
        desktop = 14;
        popups = 12;
      };
    };

    cursor = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
      size = 24;
    };
  };
}
