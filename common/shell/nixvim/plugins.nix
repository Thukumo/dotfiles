{ pkgs, ... }:

{
  programs.nixvim.plugins = {
    # UI/UX
    lualine.enable = true;
    barbar.enable = false;
    web-devicons.enable = true;
    mini = {
      enable = true;
      mockDevIcons = true;
      modules.icons = { };
    };
    dropbar.enable = true;
    zen-mode.enable = true;
    nvim-autopairs.enable = true;
    which-key.enable = true;
    noice.enable = true;

    # コメント
    comment = {
      enable = true;
      settings = {
        opleader.line = "gc";
        toggler.line = "gcc";
      };
    };

    # ナビゲーション
    telescope.enable = true;
    neo-tree.enable = true;

    # 診断/ブラウジング
    trouble.enable = true;
    tiny-inline-diagnostic = {
      enable = true;
      settings = {
        preset = "modern";
      };
    };

    # インデント・チャンク表示
    hlchunk = {
      enable = true;
      settings = {
        chunk = {
          enable = true;
        };
        indent = {
          enable = true;
        };
        line_num = {
          enable = true;
        };
      };
    };

    # Copilot
    copilot-vim.enable = false;

    # Cargo依存管理
    crates = {
      enable = true;
      settings = {
        lsp = {
          enabled = true;
          actions = true;
          completion = true;
          hover = true;
        };
      };
    };

    # cmp cmdline設定
    cmp-cmdline.enable = true;
    luasnip.enable = true;

    # Treesitter
    treesitter = {
      enable = true;
      settings = {
        highlight.enable = true;
        indent.enable = true;
        auto_install = false;
      };
      grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
        rust
        nix
        markdown
        c
        lua
        go
      ];
    };

    # マークダウン
    markdown-preview.enable = true;

    # dial.nvim
    dial = {
      enable = true;
      luaConfig.post = builtins.readFile ./luaconfig/dial.luaconfig;
    };
  };
}
