{ lib, mkForEachUsers, ... }:
{
  options.users.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        {
          options.custom.desktop.apps.chromium.enable = lib.mkEnableOption "Chromium";
        }
      )
    );
  };

  config = {
    home-manager.users = mkForEachUsers (user: user.custom.desktop.apps.chromium.enable) (
      user:
      { ... }:
      {
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
