{
  lib,
  pkgs,
  myLib,
  config,
  ...
}:
{
  options.custom.users = myLib.mkUserOption {
    options.dev.llama = {
      enable = lib.mkEnableOption "llama";
      host = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "Host of the llama-server";
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 11434;
        description = "Port of the llama-server";
      };
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.llama-cpp;
        description = "llama-cpp package to use";
      };
      prismFork = lib.mkEnableOption "PrismML fork of llama-cpp (required for Ternary Bonsai 2 PTQ1_0/PQ2_0)";
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
        description = "Models to serve (\"owner/repo/file.gguf\" or submodule)";
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
                    backend = lib.mkOption {
                      type = lib.types.enum [
                        "default"
                        "upstream"
                      ];
                      default = "default";
                      description = ''
                        llama.cpp backend for this model.
                        "upstream" builds ggml-org master (needed for architectures such as LFM3
                        that are not in the pinned Prism fork / nixpkgs 0.6.0).
                      '';
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
                    fim = lib.mkEnableOption "use this model as a FIM (fill-in-the-middle) completion candidate for nvim cmp-ai (pick the active one via dev.llama.fimModel)";
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
                    mmproj = lib.mkOption {
                      type = lib.types.nullOr (
                        lib.types.submodule {
                          options = commonOptions;
                        }
                      );
                      default = null;
                      description = "Vision tower file (--mmproj) for multimodal models.";
                    };
                    specType = lib.mkOption {
                      type = lib.types.listOf (
                        lib.types.enum [
                          "none"
                          "draft-simple"
                          "draft-eagle3"
                          "draft-mtp"
                          "draft-dspark"
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
                        - draft-dspark: DSpark speculative decoding with dedicated drafter (requires -md, e.g. Bonsai 27B).
                        - draft-dflash: DeepSeek-Flash speculative decoding.
                        - ngram-simple: n-gram based model-less speculative decoding.
                        - ngram-map-k: n-gram map (K) based speculative decoding.
                        - ngram-map-k4v: n-gram map (K4V) based speculative decoding.
                        - ngram-mod: Modified n-gram lookup speculative decoding.
                        - ngram-cache: n-gram cache based speculative decoding.
                      '';
                    };
                    specDefault = lib.mkOption {
                      type = lib.types.nullOr lib.types.int;
                      default = null;
                      description = "Max number of draft tokens for speculative decoding (--spec-draft-n-max).";
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
      fimModel = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          Name of the model used for FIM (fill-in-the-middle) completion in nvim cmp-ai.
          Must be the name of a model marked with the `fim` flag. `null` disables cmp-ai.
        '';
      };
    };
  };

  config.home-manager.users = myLib.mkForEachUsers config (user: user.custom.dev.llama.enable) (
    user:
    { config, ... }:
    let
      cfg = user.custom.dev.llama;
      baseBackend = cfg.package.override {
        inherit (cfg)
          cudaSupport
          rocmSupport
          vulkanSupport
          openclSupport
          ;
      };
      # ponytail: forkはupstream b10754ベース (tip c96baf4)。nixpkgs 0.6.0のtest patchは適用不可、npm hash/doCheckもfork用に戻す
      llamaBackend =
        if cfg.prismFork then
          baseBackend.overrideAttrs (_old: {
            version = "prism-b10754-c96baf4";
            src = pkgs.fetchFromGitHub {
              owner = "PrismML-Eng";
              repo = "llama.cpp";
              rev = "c96baf4abe24d11a50f326e40b6223b687449d63";
              hash = "sha256-qNGpilbhVGX2SFwWGtCOgsD+SmhtgIUmTqGhR/YYcck=";
            };
            # Backport of upstream #28469 (9e0e220): llama.cpp rejects exactly 2000
            # repetitions (>= vs >); the goal plugin's plan schema uses maxLength: 2000.
            patches = [ ./llama-grammar-repetition.patch ];
            doCheck = false;
            npmDepsHash = "sha256-2Q7XhaLAArmviOLdQsNbYTfdyDE5pW9lR26cRHEVl9k=";
          })
        else
          baseBackend;

      # Upstream master for architectures not yet in nixpkgs 0.6.0 / the Prism fork.
      # LFM3 (LiquidAI) landed after both; keep this separate so the Bonsai pin stays put.
      # CUDA arch is fixed to the 16x-aurora GPU (RTX 5060, sm_120a); adjust for other hosts.
      upstreamBackend =
        let
          cuda = cfg.cudaSupport;
          stdenv = if cuda then pkgs.cudaPackages.backendStdenv else pkgs.stdenv;
          runtimeLibs = [
            pkgs.openssl
          ]
          ++ lib.optionals cuda (
            with pkgs.cudaPackages;
            [
              cuda_cudart
              libcublas
            ]
          );
        in
        stdenv.mkDerivation {
          pname = "llama-cpp-upstream";
          version = "0.7.0-8ca4060";
          src = pkgs.fetchFromGitHub {
            owner = "ggml-org";
            repo = "llama.cpp";
            rev = "8ca4060b7e30e76baaa5670ee1ec1b760b7f8552";
            hash = "sha256-tcHjp0tU23+jbXVHARZ7OBeT6M70Bi0MS4NKa3/rFhQ=";
          };
          nativeBuildInputs = [
            pkgs.cmake
            pkgs.ninja
            pkgs.pkg-config
            pkgs.patchelf
          ]
          ++ lib.optionals cuda [
            pkgs.cudaPackages.cuda_nvcc
            pkgs.autoAddDriverRunpath
          ];
          buildInputs = runtimeLibs ++ lib.optionals cuda [ pkgs.cudaPackages.cccl ];
          cmakeFlags = [
            "-DCMAKE_BUILD_TYPE=Release"
            "-DLLAMA_BUILD_SERVER=ON"
            "-DLLAMA_BUILD_TESTS=OFF"
            "-DLLAMA_BUILD_EXAMPLES=OFF"
            "-DLLAMA_BUILD_UI=OFF"
            "-DLLAMA_USE_PREBUILT_UI=OFF"
            "-DLLAMA_CURL=OFF"
            "-DBUILD_SHARED_LIBS=ON"
            "-DGGML_NATIVE=OFF"
            "-DGGML_BACKEND_DL=ON"
            "-DGGML_BACKEND_DIR=${placeholder "out"}/bin"
            "-DCMAKE_BUILD_WITH_INSTALL_RPATH=ON"
            "-DCMAKE_INSTALL_RPATH=${placeholder "out"}/bin:${lib.makeLibraryPath runtimeLibs}"
          ]
          ++ lib.optionals cuda [
            "-DGGML_CUDA=ON"
            "-DCMAKE_CUDA_ARCHITECTURES=120a"
          ];
          doCheck = false;
          buildPhase = ''
            runHook preBuild
            cmake --build . -j $NIX_BUILD_CORES --target llama-server llama-cli llama-mtmd-cli
            runHook postBuild
          '';
          installPhase = ''
            runHook preInstall
            mkdir -p $out/bin
            cp -a bin/. $out/bin/
            runHook postInstall
          '';
          postFixup = ''
            for f in $out/bin/*; do
              [ -e "$f" ] || continue
              patchelf --add-rpath "$out/bin:${lib.makeLibraryPath runtimeLibs}" "$f" 2>/dev/null || true
            done
          '';
        };

      modelDir = "${config.home.homeDirectory}/.local/share/llama/models";

      allDownloads = lib.flatten (
        builtins.map (
          m:
          [ { inherit (m) repoId file; } ]
          ++ (if m.draft != null then [ { inherit (m.draft) repoId file; } ] else [ ])
          ++ (if m.mmproj != null then [ { inherit (m.mmproj) repoId file; } ] else [ ])
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
                    mmprojArg = if m.mmproj != null then "--mmproj ${modelDir}/${m.mmproj.file}" else "";
                    specTypeArg =
                      let
                        finalSpecType = if m.specType == [ ] then [ "none" ] else m.specType;
                      in
                      if finalSpecType != [ "none" ] then "--spec-type ${lib.concatStringsSep "," finalSpecType}" else "";
                    specDefaultArg =
                      if m.specDefault != null then "--spec-draft-n-max ${builtins.toString m.specDefault}" else "";
                    flashAttnArg = if m.flashAttn then "-fa on" else "-fa off";
                    cacheKArg = if m.cacheTypeK != null then "-ctk ${m.cacheTypeK}" else "";
                    cacheVArg = if m.cacheTypeV != null then "-ctv ${m.cacheTypeV}" else "";
                    mlockArg =
                      if cfg.mlock then if m.backend == "upstream" then "--load-mode mlock" else "--mlock" else "";
                    cacheReuseArg =
                      if cfg.cacheReuse != null then "--cache-reuse ${builtins.toString cfg.cacheReuse}" else "";
                    extraArgsStr = lib.concatStringsSep " " m.extraArgs;
                  in
                  {
                    name = modelName;
                    value = {
                      cmd = ''
                        # ''${PORT} is a macro placeholder replaced dynamically by llama-swap at launch
                        ${lib.getExe' (if m.backend == "upstream" then upstreamBackend else llamaBackend) "llama-server"} \
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
                          ${specDefaultArg} \
                          ${speculativeArgs} \
                          ${mmprojArg} \
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

  config.systemd.services."user@".serviceConfig =
    lib.mkIf (myLib.anyUser config (user: user.dev.llama.enable))
      {
        LimitMEMLOCK = "infinity";
      };
}
