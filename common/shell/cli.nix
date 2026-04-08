{ pkgs, ... }:

{
  home.packages = with pkgs; [
    nushell

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

    # yazi用
    vlc
    feh
    fd
    ripgrep

    gdu

    clang
    cargo

    p7zip

    wiremix

    wl-clipboard-rs
    pre-commit
  ];

  home.shellAliases = {
    ls = "${pkgs.lsd}/bin/lsd";
    pres = "${pkgs.gnutar}/bin/tar -I 'zstd -T0'";
    sl = "nix shell";
  };

  programs.yazi = {
    enable = true;
    settings = {
      mgr = {
        linemode = "mtime";
      };
      opener = {
        edit = [
          {
            run = ''nvim "$@"'';
            block = true;
          }
        ];
        play = [
          {
            # run = ''vlc "$@"'';
            run = ''${pkgs.ffmpeg}/bin/ffplay -i "$@"'';
          }
        ];
      };
    };
  };
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "adwaita";
    };
  };
}
