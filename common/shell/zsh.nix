{
  pkgs,
  osConfig,
  config,
  ...
}:

{
  home.packages = with pkgs; [
    zsh-completions
  ];

  programs.zsh = {
    enable = osConfig.users.users.${config.home.username}.shell == pkgs.zsh;

    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 10000;
      path = "${config.home.homeDirectory}/.local/state/zsh/history";
      share = true;
      ignoreDups = true;
    };

    initContent = ''
      # fish-like behavior for up/down arrows
      bindkey '^[[A' up-line-or-search
      bindkey '^[[B' down-line-or-search

      # Case-insensitive completion
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

      # Completion menu selection (like fish)
      zstyle ':completion:*' menu select
    '';
  };
}
