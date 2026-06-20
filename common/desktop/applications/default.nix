{ lib, ... }:
{
  options.custom.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.desktop.apps = {
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

          # From misc.nix
          libreoffice.enable = lib.mkEnableOption "LibreOffice";
          gnome-disk-utility.enable = lib.mkEnableOption "GNOME Disk Utility";
          thunar.enable = lib.mkEnableOption "Thunar";
        };
      }
    );
  };

  imports = map (name: ./. + "/${name}") (
    builtins.attrNames (
      lib.filterAttrs (
        name: type: type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix"
      ) (builtins.readDir ./.)
    )
  );
}
