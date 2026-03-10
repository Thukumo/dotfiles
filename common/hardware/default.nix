{ lib, ... }:

{
  imports = map (name: ./. + "/${name}") (
    builtins.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./.))
  );
}
