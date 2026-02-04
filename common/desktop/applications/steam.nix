{
  config,
  lib,
  myLib,
  ...
}:

{
  options.custom.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.desktop.apps.steam.enable = lib.mkEnableOption "Steam";
      }
    );
  };

  config =
    lib.mkIf
      (builtins.any (userConfig: userConfig.desktop.apps.steam.enable or false) (
        builtins.attrValues config.custom.users
      ))
      {
        hardware.graphics.enable32Bit = true;
        programs.steam.enable = true;
        home-manager.users =
          myLib.mkForEachUsers (user: user.custom.desktop.apps.steam.enable or false)
            (_: {
              home.persistence."/persist".directories = [
                ".local/share/Steam"
                ".local/share/applications" # たぶんアプリランチャーにゲームを表示するために入れてる
              ];
            });
      };
}
