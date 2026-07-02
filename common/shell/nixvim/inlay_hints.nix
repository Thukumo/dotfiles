_: {
  programs.nixvim = {
    autoCmd = [
      {
        event = [ "LspAttach" ];
        pattern = [ "*" ];
        callback.__raw = ''
          function()
            vim.defer_fn(function()
              vim.lsp.inlay_hint.enable(true, { bufnr = 0 })
            end, 500)
          end
        '';
      }
      {
        event = [ "InsertEnter" ];
        pattern = [ "*" ];
        callback.__raw = ''
          function()
            vim.lsp.inlay_hint.enable(false, { bufnr = 0 })
          end
        '';
      }
      {
        event = [ "InsertLeave" ];
        pattern = [ "*" ];
        callback.__raw = ''
          function()
            vim.lsp.inlay_hint.enable(true, { bufnr = 0 })
          end
        '';
      }
    ];
  };
}
