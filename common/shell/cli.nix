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
    pres = "${pkgs.gnutar}/bin/tar -I 'zstd -T0'";
    sl = "nix shell";
  };

}
