{
  lib,
  myLib,
  config,
  ...
}:
let
  agentsContent = ''
    This system runs NixOS. If a required development tool or package is not installed, use `nix shell nixpkgs#<package>` to provision and execute it.
    If a necessary repository is not available locally, you may clone it into /tmp/opencode and use it from there.
  '';
  agentsFile = builtins.toFile "opencode-agents.md" agentsContent;
in
{
  options.custom.users = myLib.mkUserOption {
    options.dev.opencode = {
      enable = lib.mkEnableOption "opencode";
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
      { lib, config, ... }:
      let
        models =
          user.custom.dev.opencode.models
          ++ lib.optionals (user.custom ? dev.llama && user.custom.dev.llama.enable) (
            map (m: m.name) user.custom.dev.llama.models
          );
      in
      {
        age.secrets."opencode_auth" = {
          file = ./auth_tsukumo.age;
          path = ".local/share/opencode/auth.json";
        };

        age.secrets."opencode_web_password" = lib.mkIf user.custom.dev.opencode.web.enable {
          file = ./opencode-web-password.age;
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
          settings = {
            "$schema" = "https://opencode.ai/config.json";

            "instructions" = [ "${agentsFile}" ];

            "plugin" = [
              "@dietrichgebert/ponytail"
              "@prevalentware/opencode-goal-plugin"
            ];

            # セッション永続化: ファイルシステムスナップショットを有効化（undo/redo用）
            "snapshot" = true;

            # コンテキスト圧縮時の保持ターン数を増やして会話の文脈を維持
            "compaction" = {
              "auto" = true;
              "tail_turns" = 10;
              "prune" = true;
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

          tui = {
            plugin = [ "@mesaleh/opencode-tps" ];
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
