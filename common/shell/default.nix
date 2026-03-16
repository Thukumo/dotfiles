{ lib, myLib, ... }:

{
  home-manager.users = myLib.mkForEachUsers (user: true) (user: {
    home.shellAliases = {
      insomnia = "touch /tmp/no-suspend";
      sleepy = "rm -f /tmp/no-suspend";
    };

    imports = map (name: ./. + "/${name}") (
      builtins.attrNames (
        lib.filterAttrs (
          name: type: type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix"
        ) (builtins.readDir ./.)
      )
    );
  });
}
