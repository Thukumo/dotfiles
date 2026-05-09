{ lib, myLib, ... }:

{
  options.custom.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.shell.private.enable = lib.mkEnableOption "private shell secrets";
      }
    );
  };

  config.home-manager.users = lib.mkMerge [
    (myLib.mkForEachUsers (_: true) (_: {
      imports = map (name: ./. + "/${name}") (
        builtins.attrNames (
          lib.filterAttrs (
            name: type:
            (type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix")
            || (type == "directory" && name != "private")
          ) (builtins.readDir ./.)
        )
      );
    }))
    (myLib.mkForEachUsers (user: user.custom.shell.private.enable or false) (_: {
      imports = [ ./private ];
    }))
  ];
}
