{ pkgs, ... }:

{
  programs.nixvim = {
    # カスタムプラグイン(NixVimモジュール化されていないもの)
    extraPlugins = [
      {
        plugin = pkgs.vimUtils.buildVimPlugin {
          name = "accelerated-jk.nvim";
          src = pkgs.fetchFromGitHub {
            owner = "rainbowhxch";
            repo = "accelerated-jk.nvim";
            rev = "8fb5dad4ccc1811766cebf16b544038aeeb7806f";
            hash = "sha256-zpjqCARlQU6g50s8wpaqN9xFK4tdUbrxU6MJrQZfSA8=";
          };
        };
      }
      {
        plugin = pkgs.vimUtils.buildVimPlugin {
          name = "tobira.nvim";
          src = pkgs.fetchFromGitHub {
            owner = "kamegoro";
            repo = "tobira.nvim";
            rev = "cd286ca662703b9d9082704892995565aac9f048";
            hash = "sha256-V5Q+uK8X37CYG0nZfJSUnRfKoZsOF/CWrQYY8dw4f7I=";
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
