{
  lib,
  myLib,
  config,
  pkgs,
  ...
}:
let
  agentsContent = ''
    This system runs NixOS. If a required development tool or package is not installed, use `nix shell nixpkgs#<package>` to provision and execute it.
    If a necessary repository is not available locally, you may clone it into /tmp/opencode and use it from there.
  '';
  agentsFile = builtins.toFile "opencode-agents.md" agentsContent;

  # デスクトップ操作MCP。
  computerUseLinux = pkgs.stdenvNoCC.mkDerivation {
    pname = "computer-use-linux";
    version = "0.7.60";

    src = pkgs.fetchurl {
      url = "https://github.com/agent-sh/computer-use-linux/releases/download/v0.7.60/computer-use-linux-x86_64-unknown-linux-musl";
      hash = "sha256-KvSekz7ZKdfLLV2mRIwG+mBkB3zhZFUYRzHWhbdpdMk=";
    };
    indicator = pkgs.fetchurl {
      url = "https://github.com/agent-sh/computer-use-linux/releases/download/v0.7.60/computer-use-linux-indicator-x86_64-unknown-linux-musl";
      hash = "sha256-8VXNUiMPrWAT8KbXADpclB7KOTIs0w/iKCXUSwbUIfA=";
    };

    dontUnpack = true;
    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 "$src" "$out/bin/computer-use-linux"
      install -Dm755 "$indicator" "$out/bin/computer-use-linux-indicator"
      runHook postInstall
    '';

    meta = {
      description = "Native Linux desktop control for AI agents";
      homepage = "https://github.com/agent-sh/computer-use-linux";
      license = lib.licenses.mit;
      mainProgram = "computer-use-linux";
      platforms = [ "x86_64-linux" ];
    };
  };

  # wtype は仮想キーボード、glib は AT-SPI の gsettings/gdbus 用。
  computerUseLinuxWrapped = pkgs.writeShellScriptBin "computer-use-linux" ''
    export PATH="${
      lib.makeBinPath [
        pkgs.wtype
        pkgs.glib
        pkgs.dconf
      ]
    }:$PATH"
    export GSETTINGS_SCHEMA_DIR="${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas"
    export COMPUTER_USE_LINUX_INDICATOR_BIN="${computerUseLinux}/bin/computer-use-linux-indicator"
    exec "${computerUseLinux}/bin/computer-use-linux" "$@"
  '';
in
{
  options.custom.users = myLib.mkUserOption {
    options.dev.opencode = {
      enable = myLib.mkEnabledOption "opencode";
      models = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Extra models to register for the llama provider (llama models are added automatically when llama is enabled)";
      };
      web = {
        enable = lib.mkEnableOption "opencode web server";
        port = lib.mkOption {
          type = lib.types.port;
          default = 4096;
          description = "Port the opencode web server listens on (127.0.0.1 only)";
        };
      };
    };
  };

  config = {
    home-manager.users = myLib.mkForEachUsers config (user: user.custom.dev.opencode.enable) (
      user:
      {
        lib,
        config,
        ...
      }:
      let
        models =
          user.custom.dev.opencode.models
          ++ lib.optionals (user.custom ? dev.llama && user.custom.dev.llama.enable) (
            map (m: m.name) user.custom.dev.llama.models
          );
      in
      {
        home.packages = [ computerUseLinuxWrapped ];

        age.secrets = {
          opencode_auth = {
            file = ./auth_tsukumo.age;
            path = ".local/share/opencode/auth.json";
          };
        }
        // lib.optionalAttrs user.custom.dev.opencode.web.enable {
          opencode_web_password.file = ./opencode-web-password.age;
        };

        systemd.user.services.opencode-web = lib.mkIf user.custom.dev.opencode.web.enable {
          Unit = {
            Description = "opencode web server";
            After = [ "agenix.service" ];
          };
          Service = {
            ExecStart = "${config.programs.opencode.package}/bin/opencode serve --hostname 127.0.0.1 --port ${toString user.custom.dev.opencode.web.port}";
            EnvironmentFile = [ "%t/agenix/opencode_web_password" ];
            Restart = "on-failure";
            RestartSec = "5";
          };
          Install.WantedBy = [ "default.target" ];
        };

        programs.opencode = {
          enable = true;
          # OpenCode 2 は cli.json を TUI から書き換えるため、宣言設定は
          # home-manager-cli.json / OPENCODE_CLI_CONFIG_CONTENT 側に逃がす。
          mutableSettings = true;
          settings = {
            "$schema" = "https://opencode.ai/config.json";

            "instructions" = [ "${agentsFile}" ];

            "plugins" = [
              "@dietrichgebert/ponytail"
              "@prevalentware/opencode-goal-plugin"
              "opencode-tps-meter"
            ];

            # セッション永続化: ファイルシステムスナップショットを有効化（undo/redo用）
            "snapshots" = true;

            "mcp"."servers"."desktop" = {
              "type" = "local";
              "command" = [
                "${computerUseLinuxWrapped}/bin/computer-use-linux"
                "mcp"
              ];
            };

            "compaction" = {
              "auto" = true;
            };

            "provider" = {
              "llama" = {
                "npm" = "@ai-sdk/openai-compatible";
                "name" = "Llama (local)";
                "options" = {
                  "baseURL" = "http://${user.custom.dev.llama.host}:${toString user.custom.dev.llama.port}/v1";
                };
                "models" = builtins.listToAttrs (
                  builtins.map (model: {
                    name = model;
                    value = {
                      name = model;
                      # llama-serverはリクエスト毎のreasoning_effortに対応。
                      # AI SDK openai-compatibleがreasoningEffortを中継する。
                      # Tabで切替 (default = テンプレート既定)。
                      "variants" = {
                        "low" = {
                          "reasoningEffort" = "low";
                        };
                        "medium" = {
                          "reasoningEffort" = "medium";
                        };
                        "high" = {
                          "reasoningEffort" = "high";
                        };
                        "xhigh" = {
                          "reasoningEffort" = "xhigh";
                        };
                        "max" = {
                          "reasoningEffort" = "max";
                        };
                      };
                    };
                  }) models
                );
              };
            };
          };

          # stylix は OpenCode 1 向けに tui.theme を書くので、V2 では無効化して cli 側で指定する
          tui = lib.mkForce { };
          cli = {
            plugins = [ "opencode-tps-meter" ];
            session = {
              thinking = "show";
              verbosity = "high";
            };
            theme = {
              name = "stylix";
              mode = "system";
            };
          };
        };
        home.persistence."/persist".directories = [
          ".local/share/opencode"
          ".local/state/opencode"
        ];
      }
    );
  };
}
