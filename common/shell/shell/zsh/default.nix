{
  pkgs,
  lib,
  osConfig,
  config,
  ...
}:
let
  isEnabled = osConfig.users.users.${config.home.username}.shell == pkgs.zsh;
in
{
  programs.zsh = {
    enable = isEnabled;

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
        file = "share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh";
      }
      {
        name = "zsh-history-substring-search";
        src = pkgs.zsh-history-substring-search;
        file = "share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh";
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
  home.persistence."/persist".directories = lib.optionals isEnabled [
    ".local/state/zsh"
  ];
}
