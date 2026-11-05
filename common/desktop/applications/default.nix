{
  lib,
  config,
  myLib,
  ...
}:
let
  inherit ((import ../../../const/browser-registry.nix)) browsers;
in
{
  options.custom.users = myLib.mkUserOption (
    { config, ... }:
    let
      # `mimeBrowser`/`browser` で選んだブラウザはインストールを自動化する。
      browserAppEnabled =
        browser: config.desktop.mimeBrowser == browser || config.desktop.browser == browser;
    in
    {
      options.desktop = {
        mimeBrowser = lib.mkOption {
          type = lib.types.nullOr (lib.types.enum (lib.attrNames browsers));
          default = null;
          description = "Browser to set as the default MIME handler";
        };
        browser = lib.mkOption {
          type = lib.types.nullOr (lib.types.enum (lib.attrNames browsers));
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
          rquickshare.enable = lib.mkEnableOption "rQuickShare";
          slack.enable = lib.mkEnableOption "Slack";
          steam.enable = lib.mkEnableOption "Steam";
          stirling-pdf.enable = lib.mkEnableOption "stirling-pdf";
          zoom.enable = lib.mkEnableOption "Zoom";

          sidra.enable = lib.mkEnableOption "Sidra (Apple Music desktop client)";

          # From misc.nix
          libreoffice.enable = lib.mkEnableOption "LibreOffice";
          onlyoffice.enable = lib.mkEnableOption "OnlyOffice";

          # From librewolf.nix
          librewolf = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = browserAppEnabled "librewolf";
              description = "LibreWolf";
            };
            extensions = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "LibreWolf extensions to install from AMO (extension GUID; AMO accepts the GUID in its download URL). The declared set is authoritative: extensions not listed are removed and manual installation is blocked.";
            };
            settings = lib.mkOption {
              type = lib.types.attrsOf (
                lib.types.oneOf [
                  lib.types.bool
                  lib.types.int
                  lib.types.float
                  lib.types.str
                ]
              );
              default = { };
              description = "LibreWolf preference overrides written to librewolf.overrides.cfg as defaultPref(). They act as defaults: changes made in the UI take precedence.";
            };
          };
          gnome-disk-utility.enable = lib.mkEnableOption "GNOME Disk Utility";
          thunar.enable = lib.mkEnableOption "Thunar";
        };
      };
    }
  );

  config.assertions = lib.mapAttrsToList (
    name: user:
    let
      selected = lib.filter (b: b != null) [
        user.desktop.mimeBrowser
        user.desktop.browser
      ];
    in
    {
      assertion = lib.all (b: user.desktop.apps.${b}.enable) selected;
      message = ''
        custom.users.${name}: desktop.mimeBrowser/browser selects a browser whose
        apps.<browser>.enable is false. Enable the app or choose another browser.
      '';
    }
  ) config.custom.users;

  imports = myLib.mkImportModules ./. [ ];
}
