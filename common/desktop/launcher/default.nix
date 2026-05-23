{ lib, ... }:
{
  options.custom.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.desktop.launcher = lib.mkOption {
          type = lib.types.nullOr (lib.types.enum [ "fuzzel" ]);
          default = null;
          description = "Application launcher to use";
        };
      }
    );
  };

  imports = map (name: ./. + "/${name}") (
    builtins.attrNames (
      lib.filterAttrs (
        name: type: type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix"
      ) (builtins.readDir ./.)
    )
  );
}
