{ pkgs, ... }:

{
  home.packages = with pkgs; [
    lazygit

    nerd-fonts.adwaita-mono
    fastfetch
    btop
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
    ./nvim.nix
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
    settings.git_protocol = "https";
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
  home.file = {
  };
  home.sessionVariables = {
    # EDITOR = "emacs";
  };
  home.shellAliases = {
    ls = "lsd";
  };
}
