{ myLib, ... }:

{
  imports = myLib.mkImportModuleFiles ./.;
  programs.nixvim.plugins.lsp.enable = true;
}
