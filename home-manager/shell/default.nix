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
    
    lsd
  ];
  imports = [
    ./nixvim.nix
    ./convd-md2pdf
  ];
  home.sessionPath = [
    "$HOME/.cargo/bin"
  ];
  home.shell.enableFishIntegration = true;
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Tsukumo";
        email = "92912896+Thukumo@users.noreply.github.com";
      };
    };
  };
  programs.gh = {
    enable = true;
  };
  programs.lazygit = {
    enable = true;
    settings = {};
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
            run = ''ffplay -i "$@"'';
          }
        ];
      };
    };
  };
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "adapta";
    };
  };
  home.file = {
  };
  home.sessionVariables = {
    # EDITOR = "emacs";
  };
  home.shellAliases = {
    ls = "lsd";
  };
}
