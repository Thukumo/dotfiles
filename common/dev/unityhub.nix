{
  lib,
  config,
  myLib,
  pkgs,
  ...
}:

{
  options.custom.users = myLib.mkUserOption {
    options.dev.unityhub.enable = lib.mkEnableOption "Unity Hub";
  };

  config = lib.mkIf (myLib.anyUser config (user: user.dev.unityhub.enable)) {
    nixpkgs.config.allowUnfreePackages = [
      pkgs.unityhub.pname
      pkgs.corefonts.pname
    ];
    home-manager.users = myLib.mkForEachUsers config (user: user.custom.dev.unityhub.enable) (
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
