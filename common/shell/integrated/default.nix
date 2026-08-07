{ myLib, ... }:
{
  imports = myLib.mkImportModules ./. [ "private" ];
}
