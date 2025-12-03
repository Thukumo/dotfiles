{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      tiny-inline-diagnostic-nvim
      nvim-autopairs
      lualine-nvim
      denops-vim
      markdown-preview-nvim
      nvim-treesitter-context
      vim-repeat
      barbar-nvim
      # barbar.nvimの(任意)依存プラグイン
      nvim-web-devicons

      dropbar-nvim
      trouble-nvim
      hlchunk-nvim
      # hlchunkの依存プラグイン
      # とりあえず対応してる全言語のパーサを入れとく
      nvim-treesitter.withAllGrammars

      zen-mode-nvim
      tokyonight-nvim


      nvim-lspconfig

      mason-nvim
      mason-lspconfig-nvim

      # LSP補完
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      cmp-cmdline
      luasnip
      cmp_luasnip

      # ファジーファインダー
      telescope-nvim
      plenary-nvim

      # copilot
      copilot-vim

      (pkgs.vimUtils.buildVimPlugin {
        name = "hellshake-yano.vim";
        src = builtins.fetchGit {
          url = "https://github.com/nekowasabi/hellshake-yano.vim";
          rev = "294a171e2fd8259d71c6fcc2e448979747a85cca";
        };
      })
      (pkgs.vimUtils.buildVimPlugin {
        name = "nanode.nvim";
        src = builtins.fetchGit {
          url = "https://github.com/KijitoraFinch/nanode.nvim";
          rev = "cd85bbb5195b23adfb89a695b54e16daab259800";
        };
      })
      # (pkgs.vimUtils.buildVimPlugin {
      #   name = "tabset.vim";
      #   src = builtins.fetchGit {
      #     url = "https://github.com/FotiadisM/tabset.nvim";
      #     rev = "996f95e4105d053a163437e19a40bd2ea10abeb2";
      #   };
      # })
      (pkgs.vimUtils.buildVimPlugin {
        name = "accelerated-jk.nvim";
        src = builtins.fetchGit {
          url = "https://github.com/rainbowhxch/accelerated-jk.nvim";
          rev = "8fb5dad4ccc1811766cebf16b544038aeeb7806f";
        };
      })
    ];
    extraPackages = with pkgs; [
      watchexec
      deno
      wget
      rust-analyzer
      go
      gopls
      nil
      clang-tools
      lua-language-server
    ];
    extraLuaConfig = (builtins.readFile ./init.lua);
    extraConfig = (builtins.readFile ./init.vim);
  };
}
