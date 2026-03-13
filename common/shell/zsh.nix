{ pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 10000;
      path = "$HOME/.zsh_history";
    };

    initExtra = ''
      # fish-like behavior for up/down arrows
      bindkey '^[[A' up-line-or-search
      bindkey '^[[B' down-line-or-search
    '';
  };
}
