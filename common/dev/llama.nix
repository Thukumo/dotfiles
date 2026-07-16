{
  lib,
  pkgs,
  myLib,
  ...
}:
{
  options.custom.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.dev.llama = {
          enable = lib.mkEnableOption "llama";
          host = lib.mkOption {
            type = lib.types.str;
            default = "127.0.0.1";
          };
          port = lib.mkOption {
            type = lib.types.port;
            default = 11434;
          };
          package = lib.mkOption {
            type = lib.types.package;
            default = pkgs.llama-cpp;
          };
          cudaSupport = lib.mkEnableOption "CUDA GPU acceleration";
          rocmSupport = lib.mkEnableOption "ROCm GPU acceleration";
          vulkanSupport = lib.mkEnableOption "Vulkan GPU acceleration";
          openclSupport = lib.mkEnableOption "OpenCL GPU acceleration";
          mlock = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Force system to keep model in RAM rather than swapping or compressing.";
          };
          cacheReuse = lib.mkOption {
            type = lib.types.nullOr lib.types.int;
            default = 256;
            description = "Minimum chunk size to attempt reusing from the cache via KV shifting. Null to use default.";
          };
          models = lib.mkOption {
            # String または AttrSet を受け取るハイブリッド型
            type = lib.types.listOf (
              lib.types.coercedTo lib.types.str
                (str: {
                  # "owner/repo/file.gguf" のような簡易文字列からパース
                  repoId = lib.concatStringsSep "/" (lib.take 2 (lib.splitString "/" str));
                  file = lib.last (lib.splitString "/" str);
                })
                (
                  lib.types.submodule (
                    { config, ... }:
                    let
                      commonOptions = {
                        repoId = lib.mkOption { type = lib.types.str; };
                        file = lib.mkOption { type = lib.types.str; };
                        gpuLayers = lib.mkOption {
                          type = lib.types.oneOf [
                            lib.types.int
                            (lib.types.enum [ "auto" ])
                          ];
                          default = "auto";
                          description = "Number of layers to offload to GPU (-ngl). Can be an integer or 'auto'.";
                        };
                        flashAttn = lib.mkOption {
                          type = lib.types.bool;
                          default = true;
                          description = "Whether to enable Flash Attention.";
                        };
                        cacheTypeK = lib.mkOption {
                          type = lib.types.nullOr (
                            lib.types.enum [
                              "f32"
                              "f16"
                              "bf16"
                              "q8_0"
                              "q4_0"
                              "q4_1"
                              "iq4_nl"
                              "q5_0"
                              "q5_1"
                            ]
                          );
                          default = "q8_0";
                          description = "KV cache data type for K. Set null to use llama.cpp defaults.";
                        };
                        cacheTypeV = lib.mkOption {
                          type = lib.types.nullOr (
                            lib.types.enum [
                              "f32"
                              "f16"
                              "bf16"
                              "q8_0"
                              "q4_0"
                              "q4_1"
                              "iq4_nl"
                              "q5_0"
                              "q5_1"
                            ]
                          );
                          default = "q8_0";
                          description = "KV cache data type for V. Set null to use llama.cpp defaults.";
                        };
                      };
                    in
                    {
                      options = commonOptions // {
                        name = lib.mkOption {
                          type = lib.types.str;
                          default = lib.removeSuffix ".gguf" config.file;
                          description = "Name of the model. Defaults to the file name without the .gguf suffix.";
                        };
                        contextLength = lib.mkOption {
                          type = lib.types.int;
                          default = 128000;
                        };

                        # ドラフトモデルのオプショナル指定
                        draft = lib.mkOption {
                          type = lib.types.nullOr (
                            lib.types.submodule {
                              options = commonOptions;
                            }
                          );
                          default = null;
                        };
                        specType = lib.mkOption {
                          type = lib.types.listOf (
                            lib.types.enum [
                              "none"
                              "draft-simple"
                              "draft-eagle3"
                              "draft-mtp"
                              "draft-dflash"
                              "ngram-simple"
                              "ngram-map-k"
                              "ngram-map-k4v"
                              "ngram-mod"
                              "ngram-cache"
                            ]
                          );
                          default = [ "none" ];
                          description = ''
                            Speculative decoding type (can specify multiple as a list for hybrid decoding):
                            - none: Normal inference (default).
                            - draft-simple: Traditional draft model speculative decoding (requires -md).
                            - draft-eagle3: Eagle-3 speculative decoding with dedicated tree draft (requires -md).
                            - draft-mtp: Multi-Token Prediction (MTP) using target model's internal heads (no external -md needed).
                            - draft-dflash: DeepSeek-Flash speculative decoding.
                            - ngram-simple: n-gram based model-less speculative decoding.
                            - ngram-map-k: n-gram map (K) based speculative decoding.
                            - ngram-map-k4v: n-gram map (K4V) based speculative decoding.
                            - ngram-mod: Modified n-gram lookup speculative decoding.
                            - ngram-cache: n-gram cache based speculative decoding.
                          '';
                        };
                        specDraftNMax = lib.mkOption {
                          type = lib.types.nullOr lib.types.int;
                          default = null;
                          description = "Max number of draft tokens for speculative decoding (MTP).";
                        };
                        extraArgs = lib.mkOption {
                          type = lib.types.listOf lib.types.str;
                          default = [ ];
                          description = "Extra arguments to pass to llama-server.";
                        };
                      };
                    }
                  )
                )
            );
            default = [ ];
          };
        };
      }
    );
  };

  config.home-manager.users = myLib.mkForEachUsers (user: user.custom.dev.llama.enable or false) (
    _:
    { myConfig, config, ... }:
    let
      cfg = myConfig.dev.llama;
      llamaBackend = cfg.package.override {
        inherit (cfg)
          cudaSupport
          rocmSupport
          vulkanSupport
          openclSupport
          ;
      };
      modelDir = "${config.home.homeDirectory}/.local/share/llama/models";

      allDownloads = lib.flatten (
        builtins.map (
          m:
          [ { inherit (m) repoId file; } ]
          ++ (if m.draft != null then [ { inherit (m.draft) repoId file; } ] else [ ])
        ) cfg.models
      );

    in
    {
      home.packages = [
        llamaBackend
      ];

      systemd.user.services.llama-swap = {
        Unit = {
          Description = "llama-swap proxy server";
          After = [
            "network.target"
            "llama-model-sync.service"
          ];
          Wants = [ "llama-model-sync.service" ];
        };
        Service =
          let
            yamlFormat = pkgs.formats.yaml { };
            configFile = yamlFormat.generate "llama-swap-config.yaml" {
              healthCheckTimeout = 120;
              models = builtins.listToAttrs (
                builtins.map (
                  m:
                  let
                    modelName = m.name;
                    # 投機サンプリング引数の組み立て
                    speculativeArgs =
                      if m.draft != null then
                        "-md ${modelDir}/${m.draft.file} -ngld ${builtins.toString m.draft.gpuLayers}"
                      else
                        "";
                    specTypeArg =
                      if m.specType != [ "none" ] && m.specType != [ ] then
                        "--spec-type ${lib.concatStringsSep "," m.specType}"
                      else
                        "";
                    specDraftNMaxArg =
                      if m.specDraftNMax != null then
                        "--spec-draft-n-max ${builtins.toString m.specDraftNMax}"
                      else if m.draft != null then
                        "--spec-draft-n-max 16"
                      else
                        "";
                    flashAttnArg = if m.flashAttn then "-fa on" else "-fa off";
                    cacheKArg = if m.cacheTypeK != null then "-ctk ${m.cacheTypeK}" else "";
                    cacheVArg = if m.cacheTypeV != null then "-ctv ${m.cacheTypeV}" else "";
                    mlockArg = if cfg.mlock then "--mlock" else "";
                    cacheReuseArg =
                      if cfg.cacheReuse != null then "--cache-reuse ${builtins.toString cfg.cacheReuse}" else "";
                    extraArgsStr = lib.concatStringsSep " " m.extraArgs;
                  in
                  {
                    name = modelName;
                    value = {
                      cmd = ''
                        # ''${PORT} is a macro placeholder replaced dynamically by llama-swap at launch
                        ${lib.getExe' llamaBackend "llama-server"} \
                          --port ''${PORT} \
                          -m ${modelDir}/${m.file} \
                          -ngl ${builtins.toString m.gpuLayers} \
                          -c ${builtins.toString m.contextLength} \
                          ${flashAttnArg} \
                          ${cacheKArg} \
                          ${cacheVArg} \
                          ${mlockArg} \
                          ${cacheReuseArg} \
                          ${specTypeArg} \
                          ${specDraftNMaxArg} \
                          ${speculativeArgs} \
                          ${extraArgsStr} \
                          --host ${cfg.host}
                      '';
                    };
                  }
                ) cfg.models
              );
            };
          in
          {
            ExecStart = "${pkgs.llama-swap}/bin/llama-swap --listen=${cfg.host}:${toString cfg.port} --config=${configFile}";
            Restart = "on-failure";
          };
        Install.WantedBy = [ "default.target" ];
      };

      home.persistence."/persist".directories = [
        (lib.removePrefix "${config.home.homeDirectory}/" modelDir)
      ];

      systemd.user.services.llama-model-sync = {
        Unit.Before = [ "llama-swap.service" ];
        Service = {
          Type = "simple";
          Restart = "on-failure";
          RestartSec = "10s";
          ExecStart = pkgs.writeShellScript "llama-sync-files" ''
            set -e
            mkdir -p "${modelDir}"
            cd "${modelDir}"

            # 1. 宣言されたファイルをダウンロード
            ${lib.concatMapStringsSep "\n" (d: ''
              if [ ! -f "${d.file}" ]; then
                echo "Downloading ${d.file} from ${d.repoId}..."
                ${pkgs.python3Packages.huggingface-hub}/bin/hf download "${d.repoId}" "${d.file}" --local-dir .
              fi
            '') allDownloads}

            # 2. 不要な古いモデルのクリーンアップ
            ${
              if allDownloads == [ ] then
                ''
                  # 必要なモデルが空の場合、存在するすべての .gguf を削除する
                  for file in *.gguf; do
                    [ -e "$file" ] || continue
                    echo "Cleaning up obsolete model file: $file"
                    rm "$file"
                  done
                ''
              else
                ''
                  # 必要なモデルがある場合、マッチしないものを削除する
                  for file in *.gguf; do
                    [ -e "$file" ] || continue
                    case "$file" in
                      ${lib.concatMapStringsSep "|" (d: lib.escapeShellArg d.file) allDownloads})
                        ;;
                      *)
                        echo "Cleaning up obsolete model file: $file"
                        rm "$file"
                        ;;
                    esac
                  done
                ''
            }
          '';
        };
        Install.WantedBy = [ "default.target" ];
      };
    }
  );
}
