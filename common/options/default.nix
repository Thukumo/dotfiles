{ ... }:

{
  imports = map (name: ./. + "${name}") (builtins.attrNames (builtins.filterAttrs (_: type: type == "directory") builtins.readDir ./.));
}
