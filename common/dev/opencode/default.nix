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
    custom.secrets.access.home = lib.mapAttrs (
      _: user:
      if user.dev.opencode.enable then
        {
          opencode_auth = {
            file = ./auth_tsukumo.age;
            path = ".local/share/opencode/auth.json";
            acceptedRisk = "home secret; user-level (AppArmor not used)";
          };
        }
        // lib.optionalAttrs user.dev.opencode.web.enable {
          opencode_web_password = {
            file = ./opencode-web-password.age;
            acceptedRisk = "home secret; user-level (AppArmor not used)";
            consumers = [ "opencode-web" ];
          };
        }
      else
        { }
    ) config.custom.users;

    home-manager.users = myLib.mkForEachUsers config (user: user.custom.dev.opencode.enable) (
      user:
      {
        lib,
        config,
        pkgs,
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
          # shortcut: nixpkgs-unstable 1d060 has opencode 2.2.5 with a stale
          # node_modules FOD hash; upstream fixed it in c399e1b7fb90. Remove
          # this override once nixpkgs includes that fix.
          package =
            if pkgs.opencode.version == "2.2.5" then
              pkgs.opencode.overrideAttrs (old: {
                node_modules = old.node_modules.overrideAttrs (_: {
                  outputHash =
                    if pkgs.stdenv.hostPlatform.isLinux then
                      "sha256-prx9dX7kUvs/E3zopkaPk5LXh3xJAy5sZeum/W8L7cA="
                    else
                      "sha256-dIveiaiPFGSItwLyeMuPDxTE9gpvvnlTCB/+nG24qCc=";
                });
              })
            else
              pkgs.opencode;
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
            session.thinking = "show";
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
