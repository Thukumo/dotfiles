{ pkgs, ... }:

{
  home.packages = with pkgs; [
    nerd-fonts.adwaita-mono
    fastfetch
    gotop
    speedtest-cli
    bluetui
    zellij
    trash-cli
    ffmpeg-full
    yt-dlp
    wev

    gdu

    clang
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
