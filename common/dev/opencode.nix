{
  lib,
  myLib,
  config,
  ...
}:
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
    home-manager.users = myLib.mkForEachUsers (user: config.custom.users.${user.name}.dev.opencode.enable or false) (
      user:
      { config, myConfig, ... }:
      {
        programs.opencode = {
          enable = true;
          settings = {
            "$schema" = "https=//opencode.ai/config.json";
            "provider" = {
              "ollama" = {
                "npm" = "@ai-sdk/openai-compatible";
                "name" = "Ollama (local)";
                "options" = {
                  "baseURL" = "http://localhost:11434/v1";
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
          # ".local/share/opencode"
        ];
      }
    );
  };
}
