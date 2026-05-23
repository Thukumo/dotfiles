{ lib, ... }:
{
  options.custom.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.desktop.de = lib.mkOption {
          type = lib.types.nullOr (lib.types.enum [ "niri" ]);
          default = null;
          description = "Desktop environment or window manager to use";
        };
      }
    );
  };

  imports = map (name: ./. + "/${name}") (
    builtins.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./.))
  );
}
