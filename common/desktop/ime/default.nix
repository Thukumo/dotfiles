{ lib, ... }:
{
  options.custom.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.desktop.ime = lib.mkOption {
          type = lib.types.nullOr (lib.types.enum [ "skk" ]);
          default = null;
          description = "Input method engine to use";
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
