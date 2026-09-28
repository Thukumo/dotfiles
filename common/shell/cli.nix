{ pkgs, ... }:

{
  home.packages = with pkgs; [
    fastfetch
    gotop
    bluetui
    zellij
    wev

    gdu

    _7zz

    wiremix

    wl-clipboard-rs

    cargo
    rustc
    clippy

    hyperfine
  ];

}
