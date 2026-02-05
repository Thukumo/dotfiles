{
  lib,
  myLib,
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

  config.home-manager.users = myLib.mkForEachUsers (user: user.custom.dev.unityhub.enable or false) (
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
}
