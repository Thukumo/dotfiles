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

    # 各プラグインのLua設定を追加で読み込み
    extraConfigLuaPost = ''
      ${builtins.readFile ./accelerated-jk.luaconfig}
      ${builtins.readFile ./hellshake-yano.luaconfig}
      ${builtins.readFile ./diagnostics.luaconfig}
      ${builtins.readFile ./dial.luaconfig}
    '';
  };
}
