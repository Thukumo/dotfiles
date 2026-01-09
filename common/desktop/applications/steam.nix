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
          enable = lib.mkEnableOption "Steam";
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
        home-manager.users = mkForEachUsers (user: user.custom.desktop.apps.steam.enable) (
          user:
          { config, ... }:
          {
            home.persistence."/persist".directories = [
              ".local/share/Steam"
              ".local/share/applications" # たぶんアプリランチャーにゲームを表示するために入れてる
            ];
          }
        );
      };
}
