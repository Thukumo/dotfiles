{ lib, myLib, ... }:
{
  options.custom.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        let
          # `mimeBrowser`/`browser` で選んだブラウザはインストールを自動化する。
          browserAppEnabled =
            browser: config.desktop.mimeBrowser == browser || config.desktop.browser == browser;
        in
        {
          options.desktop = {
            mimeBrowser = lib.mkOption {
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
            browser = lib.mkOption {
              type = lib.types.nullOr (
                lib.types.enum [
                  "chromium"
                  "google-chrome"
                  "librewolf"
                ]
              );
              default = null;
              description = "Browser opened by desktop shortcuts (e.g. Mod+Shift+C). Shortcut binds are not created when unset.";
            };
            apps = {
              blender.enable = lib.mkEnableOption "Blender";
              bottles.enable = lib.mkEnableOption "Bottles";
              chromium.enable = lib.mkOption {
                type = lib.types.bool;
                default = browserAppEnabled "chromium";
                description = "Chromium";
              };
              discord.enable = lib.mkEnableOption "Discord";
              google-chrome.enable = lib.mkOption {
                type = lib.types.bool;
                default = browserAppEnabled "google-chrome";
                description = "Google Chrome";
              };
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
                enable = lib.mkOption {
                  type = lib.types.bool;
                  default = browserAppEnabled "librewolf";
                  description = "LibreWolf";
                };
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
      )
    );
  };

  imports = myLib.mkImportModuleFiles ./.;
}
