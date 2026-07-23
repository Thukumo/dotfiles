{
  lib,
  myLib,
  ...
}:
let
  authSecretFile = ./auth_tsukumo.age;
  agentsContent = ''
    This system runs NixOS. If a required development tool or package is not installed, use `nix shell nixpkgs#<package>` to provision and execute it.
  '';
  agentsFile = builtins.toFile "opencode-agents.md" agentsContent;
in
{
  options.custom.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.dev.opencode = {
          enable = lib.mkEnableOption "opencode";
          models = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
          };
        };
      }
    );
  };

  config = {
    home-manager.users = myLib.mkForEachUsers (user: user.custom.dev.opencode.enable or false) (
      _user:
      { myConfig, ... }:
      {
        age.secrets = lib.mkIf (builtins.pathExists authSecretFile) {
          "opencode_auth" = {
            file = authSecretFile;
            path = ".local/share/opencode/auth.json";
          };
        };

        programs.opencode = {
          enable = true;
          settings = {
            "$schema" = "https://opencode.ai/config.json";

            "instructions" = [ "${agentsFile}" ];

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
                  "baseURL" = "http://${myConfig.dev.llama.host}:${toString myConfig.dev.llama.port}/v1";
                };
                "models" = builtins.listToAttrs (
                  builtins.map (model: {
                    name = model;
                    value = {
                      name = model;
                    };
                  }) myConfig.dev.opencode.models
                );
              };
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
