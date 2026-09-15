{ pkgs, ... }:

{
  home.packages = with pkgs; [
    fastfetch
    gotop
    bluetui
    zellij
    wev

    gdu

    p7zip

    wiremix

    wl-clipboard-rs

    cargo
    rustc
    clippy

    hyperfine
  ];

}
