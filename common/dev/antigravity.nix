{
  lib,
  mkForEachUsers,
  ...
}:

{
  options.users.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.custom.dev.antigravity = {
          enable = lib.mkEnableOption "Google Antigravity";
        };
      }
    );
  };
  config.home-manager.users = mkForEachUsers (user: user.custom.dev.antigravity.enable) (
    _:
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.google-antigravity
      ];
      home.persistence."/persist".directories = [
        ".antigravity"
        ".config/Antigravity"
      ];
    }
  );
}
