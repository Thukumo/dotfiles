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
  };
}
