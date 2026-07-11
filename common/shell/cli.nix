{ pkgs, ... }:

{
  home.packages = with pkgs; [
    fastfetch
    gotop
    bluetui
    zellij
    ffmpeg-full
    wev

    gdu

    p7zip

    wiremix

    wl-clipboard-rs

    cargo
  ];

  home.shellAliases = {
    sl = "nix shell";
    dc = "cd";
  };

}
