_:

{
  programs.nixvim.plugins = {
    # cmdline補完
    cmp-cmdline.enable = true;

    luasnip.enable = false;

    # Treesitter
    treesitter = {
      enable = true;
      settings = {
        highlight.enable = true;
        indent.enable = true;
        auto_install = false;
      };
    };

    # インクリメント・デクリメント
    dial = {
      enable = true;
      luaConfig.post = builtins.readFile ../luaconfig/dial.luaconfig;
    };
  };
}
