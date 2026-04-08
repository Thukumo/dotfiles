{ pkgs, ... }:

{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "upscale";
      runtimeInputs = with pkgs; [
        fd
        ffmpeg-full
      ];
      text =
        builtins.replaceStrings
          [
            "__ANIME4K_SHADER_DIR__"
            "__FFMPEG_BIN__"
            "__FFPROBE_BIN__"
          ]
          [
            "${pkgs.anime4k}"
            "${pkgs.ffmpeg-full}/bin/ffmpeg"
            "${pkgs.ffmpeg-full}/bin/ffprobe"
          ]
          (builtins.readFile ./upscale.sh);
    })
  ];
}
