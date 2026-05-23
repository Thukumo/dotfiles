{
  config,
  lib,
  desktopLib,
  ...
}:

{
  config =
    lib.mkIf
      (builtins.any (userConfig: userConfig.desktop.apps.steam.enable or false) (
        builtins.attrValues config.custom.users
      ))
      {
        hardware.graphics.enable32Bit = true;
        programs.steam = {
          enable = true;
          extest.enable = true;
        };
        home-manager.users = desktopLib.mkHome (user: user.custom.desktop.apps.steam.enable or false) (_: {
          programs.mangohud = {
            enable = true;
            enableSessionWide = true;
            settings = {
              full = true;
            };
          };
          home.persistence."/persist".directories = [
            ".local/share/Steam"
            ".local/share/applications" # たぶんアプリランチャーにゲームを表示するために入れてる
          ];
        });
      };
}
