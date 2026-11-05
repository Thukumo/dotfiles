{ myLib, ... }:

{
  imports = myLib.mkImportModules ./. [ ];
  programs.nixvim.plugins.lsp.enable = true;
}
