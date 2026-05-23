{ lib, ... }:
{
  options.custom.desktop.sessionManager = lib.mkOption {
    type = lib.types.nullOr (
      lib.types.enum [
        "greetd"
        "ly"
      ]
    );
    default = "ly";
    description = "Session manager to use";
  };

  imports = map (name: ./. + "/${name}") (
    builtins.attrNames (
      lib.filterAttrs (
        name: type: type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix"
      ) (builtins.readDir ./.)
    )
  );
}
