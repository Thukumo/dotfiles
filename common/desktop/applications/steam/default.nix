{
  config,
  lib,
  mkForEachUsers,
  ...
}:

{
  options.users.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.custom.desktop.apps.steam = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
          };
        };
      }
    );
  };

  config =
    lib.mkIf
      (builtins.any (user: user.custom.desktop.apps.steam.enable) (
        builtins.attrValues config.users.users
      ))
      {
        hardware.graphics.enable32Bit = true;
        programs.steam.enable = true;
        home-manager.users = mkForEachUsers (user: user.custom.desktop.apps.steam.enable) (user: {
          imports = [
            ./home-persistence.nix
          ];
        });
      };
}
