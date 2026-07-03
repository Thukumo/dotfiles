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
      {
        plugin = pkgs.vimUtils.buildVimPlugin {
          name = "tobira.nvim";
          src = builtins.fetchGit {
            url = "https://github.com/kamegoro/tobira.nvim";
            rev = "cd286ca662703b9d9082704892995565aac9f048";
          };
        };
      }
    ];
    extraConfigLua = ''
      ${builtins.readFile ./luaconfig/accelerated-jk.luaconfig}
      ${builtins.readFile ./luaconfig/tobira.luaconfig}
    '';
  };
}
