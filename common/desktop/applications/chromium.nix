{
  desktopLib,
  ...
}:
{
  config = {
    home-manager.users = desktopLib.mkHome (user: user.custom.desktop.apps.chromium.enable or false) (
      _: _: {
        programs.chromium = {
          enable = true;
          extensions = [
            "gighmmpiobklfepjocnamgkkbiglidom" # AdBlock
            "ammoloihpcbognfddfjcljgembpibcmb" # JShelter
          ];
        };
        xdg.mimeApps = {
          enable = true;
          defaultApplications = {
            "x-scheme-handler/http" = [ "chromium-browser.desktop" ];
            "x-scheme-handler/https" = [ "chromium-browser.desktop" ];
            "text/html" = [ "chromium-browser.desktop" ];
          };
        };
      }
    );
  };
}
