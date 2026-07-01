_:

{
  programs.nixvim = {
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

    # 診断設定
    diagnostic.settings = {
      virtual_text = false;
    };

    performance = {
      byteCompileLua = {
        enable = true;
        luaLib = true;
        nvimRuntime = true;
        plugins = true;
      };
    };
  };
}
