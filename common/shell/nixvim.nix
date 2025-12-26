{ pkgs, ... }:

{
  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    vimdiffAlias = true;
    nixpkgs.config.allowUnfree = true;

    # 基本オプション
    opts = {
      number = true;
      relativenumber = true;
      expandtab = true;
      tabstop = 2;
      shiftwidth = 2;
      clipboard = "unnamedplus";
      timeoutlen = 300;
      autoread = true;
      wrap = false;
    };

    # キーマップ
    keymaps = [
      # ブラックホールレジスタ割り当て（ヤンク汚染防止）
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
    ];

    # プラグイン設定
    plugins = {
      # UI/UX
      lualine.enable = true;
      # barbar.enable = true;
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

      # Copilot
      copilot-vim.enable = true;

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

      # LSP設定
      lsp = {
        enable = true;
        servers = {
          rust_analyzer = {
            enable = true;
            installCargo = false;
            installRustc = false;
            settings = {
              check = {
                command = "clippy";
                allTargets = true;
              };
              diagnostics = {
                enable = true;
                experimental.enable = true;
              };
              cargo = {
                allFeatures = true;
                loadOutDirsFromCheck = true;
              };
              procMacro = {
                enable = true;
              };
            };
          };
          nil_ls = {
            enable = true;
            settings = {
              diagnostics.enable = true;
              nix.flake.autoArchive = true;
            };
          };
          lua_ls = {
            enable = true;
            settings.Lua = {
              diagnostics = {
                globals = [ "vim" ];
                enable = true;
              };
              workspace.checkThirdParty = false;
            };
          };
          clangd = {
            enable = true;
            cmd = [
              "clangd"
              "--background-index"
              "--clang-tidy"
            ];
          };
          gopls = {
            enable = true;
            settings = {
              analyses = {
                unusedparams = true;
                shadow = true;
              };
              staticcheck = true;
            };
          };
        };
      };

      # 補完
      cmp = {
        enable = true;
        settings = {
          snippet.expand = "function(args) require('luasnip').lsp_expand(args.body) end";
          sources = [
            { name = "nvim_lsp"; }
            { name = "crates"; }
            { name = "luasnip"; }
            { name = "path"; }
            { name = "buffer"; }
          ];
          mapping = {
            "<CR>" = "cmp.mapping.confirm({ select = true })";
            "<Tab>" = ''
              cmp.mapping(function(fallback)
                if cmp.visible() then
                  cmp.select_next_item()
                elseif require('luasnip').expand_or_jumpable() then
                  require('luasnip').expand_or_jump()
                else
                  fallback()
                end
              end, { 'i', 's' })
            '';
            "<S-Tab>" = ''
              cmp.mapping(function(fallback)
                if cmp.visible() then
                  cmp.select_prev_item()
                elseif require('luasnip').jumpable(-1) then
                  require('luasnip').jump(-1)
                else
                  fallback()
                end
              end, { 'i', 's' })
            '';
            "<C-b>" = "cmp.mapping.scroll_docs(-4)";
            "<C-f>" = "cmp.mapping.scroll_docs(4)";
            "<C-Space>" = "cmp.mapping.complete()";
            "<C-e>" = "cmp.mapping.abort()";
            "<Down>" = "cmp.mapping.scroll_docs(4)";
            "<Up>" = "cmp.mapping.scroll_docs(-4)";
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
    };

    # カスタムプラグイン（NixVimモジュール化されていないもの）
    extraPlugins = with pkgs.vimPlugins; [
      tiny-inline-diagnostic-nvim
      hlchunk-nvim
      (pkgs.vimUtils.buildVimPlugin {
        name = "hellshake-yano.vim";
        src = builtins.fetchGit {
          url = "https://github.com/nekowasabi/hellshake-yano.vim";
          rev = "294a171e2fd8259d71c6fcc2e448979747a85cca";
        };
      })
      (pkgs.vimUtils.buildVimPlugin {
        name = "accelerated-jk.nvim";
        src = builtins.fetchGit {
          url = "https://github.com/rainbowhxch/accelerated-jk.nvim";
          rev = "8fb5dad4ccc1811766cebf16b544038aeeb7806f";
        };
      })
    ];

    # 追加Lua設定
    extraConfigLua = ''
      -- accelerated-jk初期化
      require('accelerated-jk').setup()

      -- 診断設定
      vim.diagnostic.config({ virtual_text = false })
      require('tiny-inline-diagnostic').setup()

      -- hlchunk設定
      require('hlchunk').setup({
        chunk = { enable = true },
        indent = { enable = true },
        line_num = { enable = true },
      })

      -- hellshake-yano設定
      vim.g.hellshake_yano = {
        useJapanese = true,
        useHintGroups = true,
        highlightSelected = true,
        useNumericMultiCharHints = true,
        enableTinySegmenter = true,
        singleCharKeys = "ASDFGNM@;,.",
        multiCharKeys = "BCEIOPQRTUVWXYZ",
        highlightHintMarker = {bg = "yellow", fg = "Blue"},
        highlightHintMarkerCurrent = {bg = "Red", fg = "White"},
        perKeyMinLength = { w = 3, b = 3, e = 3 },
        defaultMinWordLength = 3,
        perKeyMotionCount = { w = 1, b = 1, e = 1, h = 2, j = 2, k = 2, l = 2 },
        motionCount = 3,
        japaneseMinWordLength = 3,
        segmenterThreshold = 4,
        japaneseMergeThreshold = 4,
      }

      -- コマンドライン補完設定
      local cmp = require('cmp')
      cmp.setup.cmdline('/', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = 'buffer' }
        }
      })
      cmp.setup.cmdline(':', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = 'path' }
        }, {
          { name = 'cmdline' }
        })
      })
    '';

    # 追加パッケージ（LSP/ツール）
    extraPackages = with pkgs; [
      # CLI補助
      ripgrep
      fd

      # Rustツールチェーン
      cargo
      rustc
      rustfmt
      rust-analyzer

      # その他言語サーバー
      nil
      lua-language-server
      clang-tools
      gopls

      # その他ツール
      watchexec
      deno
      wget
    ];

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
