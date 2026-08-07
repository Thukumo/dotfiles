{ lib, myLib, ... }:
{
  options.custom.users = myLib.mkUserOption {
    options.desktop = {
      hyprlock.enable = myLib.mkEnabledOption;
      activate-linux.enable = lib.mkEnableOption "activate-linux watermark";
    };
  };

  imports =
    let
      dirs = builtins.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./.));
      files = builtins.attrNames (
        lib.filterAttrs (
          name: type: type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix"
        ) (builtins.readDir ./.)
      );
    in
    (map (name: ./. + "/${name}") dirs) ++ (map (name: ./. + "/${name}") files);
}
