{
  lib,
  config,
  myLib,
  pkgs,
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
  config =
    lib.mkIf
      (builtins.any (user: user.dev.antigravity.enable or false) (
        builtins.attrValues config.custom.users
      ))
      {
        nixpkgs.config.allowUnfreePackages = [ pkgs.antigravity-ide.pname ];
        home-manager.users = myLib.mkForEachUsers (user: user.custom.dev.antigravity.enable or false) (
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
      };
}
