{ pkgs, ... }:

{
  programs.nixvim = {
    # カスタムプラグイン(NixVimモジュール化されていないもの)
    extraPlugins = [
      {
        plugin = pkgs.vimUtils.buildVimPlugin {
          name = "hellshake-yano.vim";
          src = builtins.fetchGit {
            url = "https://github.com/nekowasabi/hellshake-yano.vim";
            rev = "294a171e2fd8259d71c6fcc2e448979747a85cca";
          };
        };
      }
      {
        plugin = pkgs.vimUtils.buildVimPlugin {
          name = "accelerated-jk.nvim";
          src = builtins.fetchGit {
            url = "https://github.com/rainbowhxch/accelerated-jk.nvim";
            rev = "8fb5dad4ccc1811766cebf16b544038aeeb7806f";
          };
        };
        config = builtins.readFile ./luaconfig/accelerated-jk.luaconfig;
      }
    ];
    globals.hellshake_yano = {
      useJapanese = true;
      useHintGroups = true;
      highlightSelected = true;
      useNumericMultiCharHints = true;
      singleCharKeys = "ASDFGNM@;,.";
      multiCharKeys = "EIOPQRTUVWXYZ";
      highlightHintMarker = {
        bg = "yellow";
	fg = "Blue";
      };
      highlightHintMarkerCurrent = {
        bg = "Red";
	fg = "White";
      };
      perKeyMinLength = {
        w = 3;
	b = 3;
	e = 3;
      };
      defaultMinWordLength = 3;
      perKeyMotionCount = {
        w = 1;
	b = 1;
	e = 1;
	h = 2;
	j = 2;
	k = 2;
	l = 2;
      };
      motionCount = 3;
      japaneseMinWordLength = 3;
      segmenterThreshold = 4;
      japaneseMergeThreshold = 4;
    };
  };
}
