{
  lib,
  pkgs,
  desktopLib,
  ...
}:

let
  moonshinePkg = pkgs.python3Packages.buildPythonPackage rec {
    pname = "moonshine-voice";
    version = "0.0.71";
    format = "wheel";
    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/ea/ca/98306e24e45e9ad82002bf19bcb954e5439dd019a09cfc634f89489fef4a/moonshine_voice-${version}-py3-none-manylinux_2_34_x86_64.whl";
      sha256 = "f27e9e11f92dc5235ebc639391f4f38d2d9fda02324d4b56ec13e0ed36bf9dd0";
    };
    propagatedBuildInputs = with pkgs.python3Packages; [
      numpy
      sounddevice
      requests
      tqdm
      filelock
      platformdirs
    ];
    doCheck = false;
  };
in

{
  options.custom.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.desktop.voice-input = {
          enable = lib.mkEnableOption "voice input (speech-to-text)";
          server = lib.mkEnableOption "persistent whisper-server (keeps model in VRAM)";
          backend = lib.mkOption {
            type = lib.types.enum [
              "moonshine"
              "faster-whisper"
              "whisper-cpp"
            ];
            default = "moonshine";
          };
          cudaSupport = lib.mkEnableOption "CUDA GPU acceleration (whisper-cpp only)";
          language = lib.mkOption {
            type = lib.types.str;
            default = "auto";
          };
          model = lib.mkOption {
            type = lib.types.str;
            default = "large-v3-turbo";
          };
        };
      }
    );
  };

  config.home-manager.users =
    desktopLib.mkHome (user: user.custom.desktop.voice-input.enable or false)
      (
        _:
        { myConfig, config, ... }:
        let
          cfg = myConfig.desktop.voice-input;
          wcpp = pkgs.whisper-cpp.override { inherit (cfg) cudaSupport; };
          fw = pkgs.whisper-ctranslate2;
          modelDir = "${config.home.homeDirectory}/.local/share/whisper/models";
          modelName = "ggml-${cfg.model}";
          modelFile =
            assert !(cfg.server && cfg.backend != "whisper-cpp");
            "${modelDir}/${modelName}.bin";

          toggleScript =
            if cfg.backend == "moonshine" then
              let
                msLang =
                  if cfg.language == "auto" then throw "moonshine requires an explicit language" else cfg.language;
              in
              pkgs.writeShellScriptBin "voice-typing" ''
                export LC_ALL=C.UTF-8
                STATE_DIR="''${XDG_STATE_HOME:-$HOME/.local}/moonshine-typing"
                PID_FILE="$STATE_DIR/rec.pid"; PIPE="$STATE_DIR/stream.pipe"
                mkdir -p "$STATE_DIR"
                if [ -f "$PID_FILE" ]; then
                  IFS=' ' read -r MPID RPID < "$PID_FILE"
                  kill "$MPID" "$RPID" 2>/dev/null || true
                  rm -f "$PID_FILE" "$PIPE"
                  ${pkgs.libnotify}/bin/notify-send "音声入力" "終了"
                else
                  ${pkgs.libnotify}/bin/notify-send "音声入力" "認識中..."
                  mkfifo "$PIPE"; export PYTHONUNBUFFERED=1
                  ${moonshinePkg}/bin/moonshine-voice mic --language ${lib.escapeShellArg msLang} \
                    2>"$STATE_DIR/log" > "$PIPE" &
                  MPID=$!
                  ( ${pkgs.gnused}/bin/sed -u '/^Listening/d;/^$/d' < "$PIPE" \
                    | while IFS= read -r line; do [ -n "$line" ] && ${pkgs.wtype}/bin/wtype -- "$line"; done ) &
                  RPID=$!
                  echo "$MPID $RPID" > "$PID_FILE"
                fi
              ''
            else
              let
                transcribeCmd =
                  if cfg.backend == "faster-whisper" then
                    ''
                      OUT_DIR="$STATE_DIR/fw"; LOG="$STATE_DIR/fw.log"
                      mkdir -p "$OUT_DIR"
                      FW_MODEL="${cfg.model}"
                      case "$FW_MODEL" in large-v3-turbo) FW_MODEL="turbo" ;; large-v3) FW_MODEL="large-v3" ;; esac
                      LANG_ARG=""; [ "$LANG" != "auto" ] && LANG_ARG="--language $LANG"
                      ${fw}/bin/whisper-ctranslate2 --model "$FW_MODEL" $LANG_ARG --vad_filter True \
                        --output_dir "$OUT_DIR" --output_format txt --device auto "$REC_WAV" >"$LOG" 2>&1
                      TEXT=$(find "$OUT_DIR" -type f -name '*.txt' -exec cat {} + 2>/dev/null || true)
                    ''
                  else if cfg.server then
                    ''
                      LOG="$STATE_DIR/whisper.log"
                      TEXT=$(${pkgs.curl}/bin/curl -s -X POST \
                        -F "file=@$REC_WAV" -F "response_format=json" \
                        http://127.0.0.1:1837/inference \
                        | ${pkgs.jq}/bin/jq -r '.text' 2>"$LOG" || true)
                    ''
                  else
                    ''
                      LOG="$STATE_DIR/whisper.log"
                      TEXT=$(${wcpp}/bin/whisper-cli -m "$MODEL" -f "$REC_WAV" -l "$LANG" -nt 2>"$LOG" || true)
                    '';
              in
              pkgs.writeShellScriptBin "voice-typing" ''
                STATE_DIR="''${XDG_STATE_HOME:-$HOME/.local}/whisper-typing"
                REC_PID_FILE="$STATE_DIR/rec.pid"; REC_RAW="$STATE_DIR/recording.raw"; REC_WAV="$STATE_DIR/recording.wav"
                MODEL="${modelFile}"; LANG="${cfg.language}"
                mkdir -p "$STATE_DIR"
                if [ ! -f "$MODEL" ] && [ "${cfg.backend}" = "whisper-cpp" ]; then
                  ${pkgs.libnotify}/bin/notify-send "音声入力" "モデルが未ダウンロードです"; exit 1
                fi
                DEVICE=@DEFAULT_SOURCE@
                if [ -f "$REC_PID_FILE" ]; then
                  PID=$(cat "$REC_PID_FILE"); kill "$PID" 2>/dev/null || true; rm -f "$REC_PID_FILE"
                  ${pkgs.libnotify}/bin/notify-send "音声入力" "文字起こし中..."
                  [ ! -s "$REC_RAW" ] && { ${pkgs.libnotify}/bin/notify-send "音声入力" "録音データが空です"; rm -f "$REC_RAW"; exit 1; }
                  LOG_FILE="$STATE_DIR/whisper.log"
                  ${pkgs.ffmpeg}/bin/ffmpeg -y -f s16le -ar 16000 -ac 1 -i "$REC_RAW" -f wav "$REC_WAV" 2>"$LOG_FILE" || {
                    ${pkgs.libnotify}/bin/notify-send "音声入力" "ffmpeg変換失敗: $(tail -1 "$LOG_FILE")"; rm -f "$REC_RAW"; exit 1
                  }
                  ${transcribeCmd}
                  TRIM=$(echo "$TEXT" | xargs)
                  if [ -n "$TRIM" ]; then
                    export LC_ALL=C.UTF-8
                    ${pkgs.wtype}/bin/wtype -- "$TRIM"
                    ${pkgs.libnotify}/bin/notify-send "音声入力" "完了"
                  else
                    ERR=""; [ -f "$LOG" ] && ERR=$(tail -3 "$LOG" | tr '\n' ' ')
                    if [ -n "$ERR" ]; then ${pkgs.libnotify}/bin/notify-send "音声入力" "認識失敗: $ERR"
                    else ${pkgs.libnotify}/bin/notify-send "音声入力" "音声が検出されませんでした"; fi
                  fi
                  rm -f "$REC_RAW" "$REC_WAV" "$LOG"; [ -d "$STATE_DIR/fw" ] && rm -rf "$STATE_DIR/fw"
                else
                  ${pkgs.libnotify}/bin/notify-send "音声入力" "録音中... (Mod+Vで停止)"
                  ${pkgs.pipewire}/bin/pw-record --target @DEFAULT_SOURCE@ --rate 16000 --channels 1 --format s16 "$REC_RAW" &
                  echo $! > "$REC_PID_FILE"
                fi
              '';
        in
        {
          home.packages = [ ];

          home.persistence."/persist".directories = [
            ".local/whisper-typing"
          ]
          ++ lib.optionals (cfg.backend != "moonshine") [ ".local/share/whisper" ]
          ++ lib.optionals (cfg.backend == "moonshine") [ ".cache/moonshine" ];

          systemd.user.services.whisper-model-sync = lib.mkIf (cfg.backend != "moonshine") {
            Unit.Description = "Whisper model synchronization";
            Service = {
              Type = "oneshot";
              ExecStart = pkgs.writeShellScript "whisper-sync-model" ''
                set -euo pipefail; mkdir -p "${modelDir}"
                if [ ! -f "${modelFile}" ]; then
                  ${wcpp}/bin/whisper-cpp-download-ggml-model "${cfg.model}" "${modelDir}"
                  ${pkgs.libnotify}/bin/notify-send "Whisper" "モデル準備完了"
                fi
              '';
            };
            Install.WantedBy = [ "default.target" ];
          };

          systemd.user.services.whisper-server = lib.mkIf (cfg.server && cfg.backend == "whisper-cpp") {
            Unit = {
              Description = "Whisper server (persistent STT)";
              After = [ "whisper-model-sync.service" ];
              Wants = [ "whisper-model-sync.service" ];
            };
            Service = {
              Type = "simple";
              ExecStart = "${wcpp}/bin/whisper-server -m ${modelFile} -l ${cfg.language} --host 127.0.0.1 --port 1837";
              Restart = "on-failure";
            };
            Install.WantedBy = [ "default.target" ];
          };

          programs.niri.settings.binds = with config.lib.niri.actions; {
            "Mod+V" = {
              action = spawn "${toggleScript}/bin/voice-typing";
              repeat = false;
            };
          };
        }
      );
}
