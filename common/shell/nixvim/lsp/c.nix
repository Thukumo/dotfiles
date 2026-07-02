_:

{
  programs.nixvim.plugins.lsp.servers.clangd = {
    enable = true;
    cmd = [
      "clangd"
      "--background-index"
      "--clang-tidy"
    ];
  };
}
