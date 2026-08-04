{
  desktopLib,
  ...
}:
{
  config = {
    home-manager.users = desktopLib.mkHome (user: user.custom.desktop.apps.chromium.enable) (
      _: _: {
        programs.chromium = {
          enable = true;
          extensions = [
            "gighmmpiobklfepjocnamgkkbiglidom" # AdBlock
            "ammoloihpcbognfddfjcljgembpibcmb" # JShelter
          ];
        };
      }
    );
  };
}
