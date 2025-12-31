{ lib, mkForEachUsers, ... }:
{
  options.users.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        {
          options.custom.desktop.apps.chromium = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = config.custom.desktop.enable;
            };
          };
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
            "x-scheme-handler/http" = [ "chromium.desktop" ];
            "x-scheme-handler/https" = [ "chromium.desktop" ];
            "text/html" = [ "chromium.desktop" ];
          };
        };
      }
    );
  };
}
