{ myLib, ... }:
{
  # Only import subdirectories that are actual modules (have a default.nix)
  imports = myLib.mkImportChildren ./. (
    name: type:
    myLib.isModuleFile name type
    || (type == "directory" && builtins.pathExists (./. + "/${name}/default.nix"))
  );
}
