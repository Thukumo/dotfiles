{ lib, config, ... }:
{
  options.custom.apps.chromium = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.custom.desktop.type != null;
    };
  };
  config = lib.mkIf config.custom.apps.chromium.enable {
    home-manager.users."tsukumo" =
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
      };
  };
}
