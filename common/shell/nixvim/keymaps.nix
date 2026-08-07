{
  config,
  ...
}:

{
  programs.nixvim.keymaps = [
    # ブラックホールレジスタ割り当て(ヤンク汚染防止)
    {
      mode = [
        "n"
        "v"
      ];
      key = "x";
      action = "\"_x";
      options.silent = true;
    }
    {
      mode = "v";
      key = "p";
      action = "\"_dP";
      options.silent = true;
    }
    # accelerated-jkのキーマップ
    {
      mode = "n";
      key = "J";
      action = "<Plug>(accelerated_jk_gj)";
    }
    {
      mode = "n";
      key = "K";
      action = "<Plug>(accelerated_jk_gk)";
    }
    # LSPキーマップ
    {
      mode = "n";
      key = "gD";
      action = config.lib.nixvim.mkRaw "vim.lsp.buf.declaration";
      options = {
        silent = true;
        desc = "Go to declaration";
      };
    }
    {
      mode = "n";
      key = "gd";
      action = config.lib.nixvim.mkRaw "vim.lsp.buf.definition";
      options = {
        silent = true;
        desc = "Go to definition";
      };
    }
    {
      mode = "n";
      key = "<C-h>";
      action = config.lib.nixvim.mkRaw "vim.lsp.buf.hover";
      options = {
        silent = true;
        desc = "Hover";
      };
    }
    {
      mode = "n";
      key = "gi";
      action = config.lib.nixvim.mkRaw "vim.lsp.buf.implementation";
      options = {
        silent = true;
        desc = "Go to implementation";
      };
    }
    {
      mode = "n";
      key = "<C-k>";
      action = config.lib.nixvim.mkRaw "vim.lsp.buf.signature_help";
      options = {
        silent = true;
        desc = "Signature help";
      };
    }
    {
      mode = "n";
      key = "<space>wa";
      action = config.lib.nixvim.mkRaw "vim.lsp.buf.add_workspace_folder";
      options = {
        silent = true;
        desc = "Add workspace folder";
      };
    }
    {
      mode = "n";
      key = "<space>wr";
      action = config.lib.nixvim.mkRaw "vim.lsp.buf.remove_workspace_folder";
      options = {
        silent = true;
        desc = "Remove workspace folder";
      };
    }
    {
      mode = "n";
      key = "<space>wl";
      action = "<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<cr>";
      options = {
        silent = true;
        desc = "List workspace folders";
      };
    }
    {
      mode = "n";
      key = "<space>D";
      action = config.lib.nixvim.mkRaw "vim.lsp.buf.type_definition";
      options = {
        silent = true;
        desc = "Type definition";
      };
    }
    {
      mode = "n";
      key = "<space>rn";
      action = config.lib.nixvim.mkRaw "vim.lsp.buf.rename";
      options = {
        silent = true;
        desc = "Rename";
      };
    }
    {
      mode = "n";
      key = "<space>ca";
      action = config.lib.nixvim.mkRaw "vim.lsp.buf.code_action";
      options = {
        silent = true;
        desc = "Code action";
      };
    }
    {
      mode = "n";
      key = "<space>gr";
      action = "<cmd>Telescope lsp_references<cr>";
      options = {
        silent = true;
        desc = "References";
      };
    }
    {
      mode = "n";
      key = "<space>e";
      action = config.lib.nixvim.mkRaw "vim.diagnostic.open_float";
      options = {
        silent = true;
        desc = "Open diagnostic";
      };
    }
    {
      mode = "n";
      key = "[d";
      action = config.lib.nixvim.mkRaw "vim.diagnostic.goto_prev";
      options = {
        silent = true;
        desc = "Previous diagnostic";
      };
    }
    {
      mode = "n";
      key = "]d";
      action = config.lib.nixvim.mkRaw "vim.diagnostic.goto_next";
      options = {
        silent = true;
        desc = "Next diagnostic";
      };
    }
    {
      mode = "n";
      key = "<space>q";
      action = config.lib.nixvim.mkRaw "vim.diagnostic.setloclist";
      options = {
        silent = true;
        desc = "Set loclist";
      };
    }
    # dial.nvim キーマップ
    {
      mode = "n";
      key = "<C-a>";
      action = "<Plug>(dial-increment)";
    }
    {
      mode = "n";
      key = "<C-x>";
      action = "<Plug>(dial-decrement)";
    }
    {
      mode = "v";
      key = "<C-a>";
      action = "<Plug>(dial-increment)";
    }
    {
      mode = "v";
      key = "<C-x>";
      action = "<Plug>(dial-decrement)";
    }
    {
      mode = "v";
      key = "g<C-a>";
      action = "<Plug>(dial-increment-additional)";
    }
    {
      mode = "v";
      key = "g<C-x>";
      action = "<Plug>(dial-decrement-additional)";
    }
  ];
}
