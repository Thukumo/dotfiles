{ pkgs, ... }:

{
  home.packages = with pkgs; [
  ];
  imports = [
  ];
  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    vimdiffAlias = true;
    nixpkgs.config.allowUnfree = true;
    opts = {
      number = true;
      expandtab = true;
      tabstop = 2;
      shiftwidth = 2;
      clipboard = "unnamedplus";
      timeoutlen = 300;
      autoread = true;
      wrap = false;
      # wrap = true;
      # breakindent = true;
      # linebreak = true;
    };
    keymaps = [
      {
        mode = ["n" "v"];
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
      # {
      #   mode = "i";
      #   key = "jj";
      #   action = "<Esc>";
      #   options.silent = true;
      # }
    ];
    plugins = {
      lualine.enable = true;
      barbar.enable = true;
      web-devicons.enable = true; # required by barbar
      dropbar.enable = true;
      zen-mode.enable = true;
      copilot-vim.enable = true; # 永続化の設定をするべき
      nvim-autopairs.enable = true;
      which-key.enable = true;
      telescope.enable = true;
      neo-tree.enable = true;
      rustaceanvim = {
        enable = true;
        settings.server.default_settings = {
          rust-analyzer = {
            check.command = "clippy";
          };
          inlayHints.lifetimeElisionHints.enable = "always";
        };
      };
      crates = {
        enable = true;
        settings = {
          smart_insert = true;
          autoload = true;
          # autoupdate = true;
        };
      };
      cmp = {
        enable = true;
        settings = {
          sources = [
            { name = "nvim_lsp"; }
            { name = "crates"; }
            { name = "path"; }
            { name = "buffer"; }
          ];
          mapping = {
            "<CR>" = "cmp.mapping.confirm({ select = true })";

            "<Tab>" = "cmp.mapping.select_next_item()";
            "<S-Tab>" = "cmp.mapping.select_prev_item()";
            "<Down>" = "cmp.mapping.scroll_docs(4)";
            "<Up>" = "cmp.mapping.scroll_docs(-4)";

            "<C-b>" = "cmp.mapping.scroll_docs(-4)";
            "<C-f>" = "cmp.mapping.scroll_docs(4)";
          };
        };
      };
      treesitter-context.enable = true;
      trouble.enable = true;
      treesitter = {
        enable = true;
        settings = {
          highlight.enable = true;
          indent.enable = true;
          ensure_installed = [
            "rust"
            "nix"
            "markdown"
            "c"
          ];
          auto_install = false;
          grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
            rust
            nix
            markdown
            c
          ];
        };
      };
      markdown-preview.enable = true;
    };
    colorschemes.tokyonight.enable = true;
    extraPackages = with pkgs; [
      ripgrep
      fd

      cargo
      rustc
      rustfmt
    ];
  };
  home.sessionPath = [
  ];
  home.file = {
  };
  home.sessionVariables = {
    EDITOR = "nvim";
  };
}

