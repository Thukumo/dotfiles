{ lib, myLib, ... }:
{
  options.custom.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.desktop = {
          hyprlock.enable = myLib.mkEnabledOption;
          activate-linux.enable = lib.mkEnableOption "activate-linux watermark";
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
