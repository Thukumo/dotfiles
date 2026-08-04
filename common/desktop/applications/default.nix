{ lib, myLib, ... }:
{
  options.custom.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.desktop = {
          browser = lib.mkOption {
            type = lib.types.nullOr (
              lib.types.enum [
                "chromium"
                "google-chrome"
                "librewolf"
              ]
            );
            default = null;
            description = "Browser to set as the default MIME handler";
          };
          apps = {
            blender.enable = lib.mkEnableOption "Blender";
            bottles.enable = lib.mkEnableOption "Bottles";
            chromium.enable = lib.mkEnableOption "Chromium";
            discord.enable = lib.mkEnableOption "Discord";
            google-chrome.enable = lib.mkEnableOption "Google Chrome";
            localsend.enable = lib.mkEnableOption "LocalSend";
            mattermost-desktop.enable = lib.mkEnableOption "Mattermost Desktop";
            mpv = {
              enable = lib.mkEnableOption "mpv with Anime4K shaders";
              gpu-api = lib.mkOption {
                type = lib.types.nullOr (
                  lib.types.enum [
                    "vulkan"
                    "opengl"
                  ]
                );
                default = null;
                description = "GPU API for mpv (null for auto)";
              };
            };
            osu.enable = lib.mkEnableOption "osu";
            prismLauncher.enable = lib.mkEnableOption "Prism Launcher";
            qutebrowser.enable = lib.mkEnableOption "qutebrowser";
            rquickshare.enable = lib.mkEnableOption "rQuickShare";
            slack.enable = lib.mkEnableOption "Slack";
            steam.enable = lib.mkEnableOption "Steam";
            stirling-pdf.enable = lib.mkEnableOption "stirling-pdf";
            zoom.enable = lib.mkEnableOption "Zoom";

            sidra.enable = lib.mkEnableOption "Sidra (Apple Music desktop client)";

            # From misc.nix
            libreoffice.enable = lib.mkEnableOption "LibreOffice";

            # From librewolf.nix
            librewolf = {
              enable = lib.mkEnableOption "LibreWolf";
              extensions = lib.mkOption {
                type = lib.types.attrsOf lib.types.str;
                default = { };
                description = "LibreWolf extensions to auto-install from AMO (extension ID → slug)";
              };
            };
            gnome-disk-utility.enable = lib.mkEnableOption "GNOME Disk Utility";
            thunar.enable = lib.mkEnableOption "Thunar";
          };
        };
      }
    );
  };

  imports = myLib.mkImportModuleFiles ./.;
}
