{ ... }:

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
      action = "<cmd>lua vim.lsp.buf.declaration()<cr>";
      options = {
        silent = true;
        desc = "Go to declaration";
      };
    }
    {
      mode = "n";
      key = "gd";
      action = "<cmd>lua vim.lsp.buf.definition()<cr>";
      options = {
        silent = true;
        desc = "Go to definition";
      };
    }
    {
      mode = "n";
      key = "<C-h>";
      action = "<cmd>lua vim.lsp.buf.hover()<cr>";
      options = {
        silent = true;
        desc = "Hover";
      };
    }
    {
      mode = "n";
      key = "gi";
      action = "<cmd>lua vim.lsp.buf.implementation()<cr>";
      options = {
        silent = true;
        desc = "Go to implementation";
      };
    }
    {
      mode = "n";
      key = "<C-k>";
      action = "<cmd>lua vim.lsp.buf.signature_help()<cr>";
      options = {
        silent = true;
        desc = "Signature help";
      };
    }
    {
      mode = "n";
      key = "<space>wa";
      action = "<cmd>lua vim.lsp.buf.add_workspace_folder()<cr>";
      options = {
        silent = true;
        desc = "Add workspace folder";
      };
    }
    {
      mode = "n";
      key = "<space>wr";
      action = "<cmd>lua vim.lsp.buf.remove_workspace_folder()<cr>";
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
      action = "<cmd>lua vim.lsp.buf.type_definition()<cr>";
      options = {
        silent = true;
        desc = "Type definition";
      };
    }
    {
      mode = "n";
      key = "<space>rn";
      action = "<cmd>lua vim.lsp.buf.rename()<cr>";
      options = {
        silent = true;
        desc = "Rename";
      };
    }
    {
      mode = "n";
      key = "<space>ca";
      action = "<cmd>lua vim.lsp.buf.code_action()<cr>";
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
      action = "<cmd>lua vim.diagnostic.open_float()<cr>";
      options = {
        silent = true;
        desc = "Open diagnostic";
      };
    }
    {
      mode = "n";
      key = "[d";
      action = "<cmd>lua vim.diagnostic.goto_prev()<cr>";
      options = {
        silent = true;
        desc = "Previous diagnostic";
      };
    }
    {
      mode = "n";
      key = "]d";
      action = "<cmd>lua vim.diagnostic.goto_next()<cr>";
      options = {
        silent = true;
        desc = "Next diagnostic";
      };
    }
    {
      mode = "n";
      key = "<space>q";
      action = "<cmd>lua vim.diagnostic.setloclist()<cr>";
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
