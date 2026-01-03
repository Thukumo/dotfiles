{
lib,
mkForEachUsers,
...
}:
{
  options.users.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.custom.dev.opencode = {
          enable = lib.mkEnableOption "opencode";
          models = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
          };
        };
      }
    );
  };

  config =
    {
      home-manager.users = mkForEachUsers (user: user.custom.dev.opencode.enable) (
        user:
        { config, ... }:
        {
          programs.opencode = {
            enable = true;
            settings = {
              "$schema" = "https=//opencode.ai/config.json";
              "provider"= {
                "ollama"= {
                  "npm"= "@ai-sdk/openai-compatible";
                  "name"= "Ollama (local)";
                  "options"= {
                    "baseURL"= "http://localhost:11434/v1";
                  };
                  "models"= builtins.listToAttrs (builtins.map (model: {
                    name = model;
                    value = {
                      name = model;
                    };
                  }) user.custom.dev.opencode.models);
                };
              };
            };
          };
          home.persistence."/persist${config.home.homeDirectory}".directories = [
            # ".local/share/opencode"
          ];
        }
      );
    };
}
