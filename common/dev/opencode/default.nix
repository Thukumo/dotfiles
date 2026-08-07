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
      };
    };
  };

  config = {
    home-manager.users = myLib.mkForEachUsers config (user: user.custom.dev.opencode.enable) (user: {
      age.secrets."opencode_auth" = {
        file = ./auth_tsukumo.age;
        path = ".local/share/opencode/auth.json";
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
                "baseURL" = "http://${user.custom.dev.llama.host}:${toString user.custom.dev.llama.port}/v1";
              };
              "models" = builtins.listToAttrs (
                builtins.map (model: {
                  name = model;
                  value = {
                    name = model;
                  };
                }) user.custom.dev.opencode.models
              );
            };
          };
        };
      };
      home.persistence."/persist".directories = [
        ".local/share/opencode"
        ".local/state/opencode"
      ];
    });
  };
}
