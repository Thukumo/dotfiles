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
    # syntaxHighlighting.enable = true; # fast-syntax-highlightingを使うため無効化

    history = {
      size = 10000;
      path = "${config.xdg.stateHome}/zsh/history";
      share = true;
      ignoreDups = true;
    };

    plugins = [
      {
        name = "fast-syntax-highlighting";
        src = pkgs.zsh-fast-syntax-highlighting;
        file = "share/zsh/site-functions/fast-syntax-highlighting.plugin.zsh";
      }
      {
        name = "zsh-history-substring-search";
        src = pkgs.zsh-history-substring-search;
        file = "share/zsh-history-substring-search/zsh-history-substring-search.zsh";
      }
    ];

    initContent = ''
      # Add zsh-completions to fpath before compinit
      fpath+=(
        ${pkgs.zsh-completions}/share/zsh-completions
        ${pkgs.nix-zsh-completions}/share/zsh/site-functions
      )

      # history-substring-search bindings (fish-like)
      bindkey '^[[A' history-substring-search-up
      bindkey '^[[B' history-substring-search-down

      # Case-insensitive completion
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

      # Completion menu selection (like fish)
      zstyle ':completion:*' menu select
    '';
  };
}
