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
    ffmpeg
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

    cloudflare-warp
    p7zip

    wiremix

    wl-clipboard-rs
  ];
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
