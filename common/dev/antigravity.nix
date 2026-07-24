{
  lib,
  myLib,
  ...
}:

{
  options.custom.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.dev.antigravity = {
          enable = lib.mkEnableOption "Google Antigravity";
        };
      }
    );
  };
  config.home-manager.users =
    myLib.mkForEachUsers (user: user.custom.dev.antigravity.enable or false)
      (
        _:
        { pkgs, ... }:
        {
          home.packages = [
            pkgs.antigravity-ide
          ];
          home.persistence."/persist".directories = [
            ".antigravity"
            ".config/Antigravity"
          ];
        }
      );
}
