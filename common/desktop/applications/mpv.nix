{
  lib,
  myLib,
  pkgs,
  ...
}:
{
  options.custom.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.desktop.apps.mpv = {
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
      }
    );
  };

  config = {
    home-manager.users = myLib.mkForEachUsers (user: user.custom.desktop.apps.mpv.enable or false) (
      _:
      { pkgs, myConfig, ... }:
      let
        anime4k = pkgs.anime4k;
        mpvConfig = myConfig.desktop.apps.mpv;
      in
      {
        programs.mpv = {
          enable = true;
          config = {
            profile = "gpu-hq";
            gpu-api = lib.mkIf (mpvConfig.gpu-api != null) mpvConfig.gpu-api;
            hwdec = "auto-safe";
          };
          bindings = {
            # Mode A (High End) - Better for high quality 1080p/720p anime
            "CTRL+1" =
              "no-osd change-list glsl-shaders set \"${anime4k}/Anime4K_Upscale_CNN_x2_L.glsl:${anime4k}/Anime4K_Restore_CNN_M.glsl:${anime4k}/Anime4K_Upscale_CNN_x2_M.glsl\"; show-text \"Anime4K: Mode A (HQ)\"";

            # Mode B (Mid End) - Balanced
            "CTRL+2" =
              "no-osd change-list glsl-shaders set \"${anime4k}/Anime4K_Upscale_CNN_x2_L.glsl:${anime4k}/Anime4K_Restore_CNN_Soft_M.glsl:${anime4k}/Anime4K_Upscale_CNN_x2_M.glsl\"; show-text \"Anime4K: Mode B (Soft)\"";

            # Mode C (Low End/SD) - For low resolution videos
            "CTRL+3" =
              "no-osd change-list glsl-shaders set \"${anime4k}/Anime4K_Upscale_CNN_x2_M.glsl:${anime4k}/Anime4K_Restore_CNN_S.glsl:${anime4k}/Anime4K_Upscale_CNN_x2_S.glsl\"; show-text \"Anime4K: Mode C (SD)\"";

            # Clear shaders
            "CTRL+0" = "no-osd change-list glsl-shaders clr \"\"; show-text \"GLSL shaders cleared\"";

            # Additional useful shaders
            "CTRL+4" =
              "no-osd change-list glsl-shaders set \"${anime4k}/Anime4K_Denoise_Bilateral_Mode.glsl\"; show-text \"Anime4K: Denoise\"";
            "CTRL+5" =
              "no-osd change-list glsl-shaders set \"${anime4k}/Anime4K_Darken_HQ.glsl\"; show-text \"Anime4K: Darken Lines\"";
            "CTRL+6" =
              "no-osd change-list glsl-shaders set \"${anime4k}/Anime4K_Thin_HQ.glsl\"; show-text \"Anime4K: Thin Lines\"";
          };
        };
      }
    );
  };
}
