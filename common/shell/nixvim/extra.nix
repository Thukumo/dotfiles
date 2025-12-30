{ pkgs, ... }:

{
  programs.nixvim = {
    # カスタムプラグイン(NixVimモジュール化されていないもの)
    extraPlugins = [
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

      -- dial.nvim設定
      local augend = require("dial.augend")
      require("dial.config").augends:register_group{
        default = {
          augend.integer.alias.decimal,
          augend.integer.alias.hex,
          augend.date.alias["%Y/%m/%d"],
          augend.constant.alias.bool,
        },
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
  };
}
