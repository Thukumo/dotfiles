{ pkgs, ... }:

{
  programs.nixvim = {
    # カスタムプラグイン(NixVimモジュール化されていないもの)
    extraPlugins = [
     {
        plugin = pkgs.vimUtils.buildVimPlugin {
          name = "accelerated-jk.nvim";
          src = builtins.fetchGit {
            url = "https://github.com/rainbowhxch/accelerated-jk.nvim";
            rev = "8fb5dad4ccc1811766cebf16b544038aeeb7806f";
          };
        };
      }
    ];
    extraConfigLua = ''
      ${builtins.readFile ./luaconfig/accelerated-jk.luaconfig}
    '';
 };
}
