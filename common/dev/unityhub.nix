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
        options.dev.unityhub.enable = lib.mkEnableOption "Unity Hub";
      }
    );
  };

  config =
    lib.mkIf
      (builtins.any (user: user.dev.unityhub.enable or false) (builtins.attrValues config.custom.users))
      {
        nixpkgs.config.allowUnfreePackages = [
          pkgs.unityhub.pname
          pkgs.corefonts.pname
        ];
        home-manager.users = myLib.mkForEachUsers config (user: user.custom.dev.unityhub.enable or false) (
          _:
          { pkgs, ... }:
          {
            home.packages = with pkgs; [
              unityhub
            ];
            home.persistence."/persist" = {
              directories = [
                "Unity"
                ".config/unity3d"
                ".config/unityhub"
                ".local/share/unity3d"
              ];
            };
          }
        );
      };
}
