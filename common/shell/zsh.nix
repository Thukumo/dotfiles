{
  pkgs,
  osConfig,
  config,
  ...
}:

{
  programs.zsh = {
    enable = osConfig.users.users.${config.home.username}.shell == pkgs.zsh;

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
