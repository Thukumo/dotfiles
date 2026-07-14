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
                        "-md ${modelDir}/${m.draft.file} -ngld ${builtins.toString m.draft.gpuLayers} --draft 16"
                      else
                        "";
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
                          ${speculativeArgs} \
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
        ".local/share/llama/models"
      ];

      systemd.user.services.llama-model-sync = {
        Unit.Before = [ "llama-swap.service" ];
        Service = {
          Type = "oneshot";
          TimeoutStartSec = 0;
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
