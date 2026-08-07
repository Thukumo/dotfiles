{ myLib, ... }:

{
  imports = myLib.mkImportModules ./. [ "luaconfig" ];
  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    vimdiffAlias = true;
  };
}
