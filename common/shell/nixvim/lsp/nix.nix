_:

{
  programs.nixvim.plugins.lsp.servers.nil_ls = {
    enable = true;
    settings = {
      diagnostics.enable = true;
      nix.flake.autoArchive = true;
    };
  };
  home.persistence."/persist".directories = [
    ".cache/nix"
  ];
}
