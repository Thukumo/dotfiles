{ lib, mkForEachUsers, ... }:

{
  home-manager.users = mkForEachUsers (user: true) (user: {
    imports =
      map (name: ./. + "/${name}") (
        builtins.attrNames (
          lib.filterAttrs (
            name: type: type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix"
          ) (builtins.readDir ./.)
        )
      );
  });
}
