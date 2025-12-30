{ ... }:

{
  imports = [
    ./options.nix
    ./keymaps.nix
    ./plugins.nix
    ./lsp.nix
    ./completion.nix
    ./extra.nix
    ./packages.nix
  ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    vimdiffAlias = true;
    nixpkgs.config.allowUnfree = true;

    colorschemes.tokyonight = {
      enable = true;
      settings.light_style = "day";
    };
  };

  # 環境変数
  home.sessionVariables = {
    EDITOR = "nvim";
  };
}
