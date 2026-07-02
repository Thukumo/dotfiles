_:

{
  programs.nixvim.plugins.lsp.servers.lua_ls = {
    enable = true;
    settings.Lua = {
      diagnostics = {
        globals = [ "vim" ];
        enable = true;
      };
      workspace.checkThirdParty = false;
    };
  };
}
