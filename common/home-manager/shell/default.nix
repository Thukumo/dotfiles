{ pkgs, config, ... }:

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

    gemini-cli
    github-copilot-cli

    gdu

    clang
    cargo

    cloudflare-warp
    p7zip

    wiremix
  ];
  imports = [
    ./nixvim.nix
    ./convd-md2pdf
  ];
  # home.sessionPath = [
  #   "$HOME/.cargo/bin"
  # ];
  home.persistence."/persist/${config.home.homeDirectory}".directories = [
    ".gemini"
  ];
  home.shell.enableFishIntegration = true;
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Tsukumo";
        email = "contact@tsukumo.f5.si";
      };
    };
  };
  programs.gh = {
    enable = true;
  };
  programs.lazygit = {
    enable = true;
    settings = { };
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
  home.file = {
  };
  home.sessionVariables = {
    # EDITOR = "emacs";
  };
  home.shellAliases = {
    ls = "${pkgs.lsd}/bin/lsd";
    cat = "${pkgs.bat}/bin/bat";
  };
}
