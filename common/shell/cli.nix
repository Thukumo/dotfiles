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

    cargo

    p7zip

    wiremix

    wl-clipboard-rs
  ];

  home.shellAliases = {
    sl = "nix shell";
  };

}
