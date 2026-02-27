{
  lib,
  config,
  pkgs,
  myLib,
  ...
}:
{
  options.custom.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.dev.ollama = {
          enable = lib.mkEnableOption "ollama";
          host = lib.mkOption {
            type = lib.types.str;
            default = "127.0.0.1";
            description = "The host address to bind to.";
          };
          package = lib.mkOption {
            type = lib.types.package;
            default = pkgs.ollama;
            description = "The ollama package to use.";
          };
          loadModels = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            apply =
              models:
              builtins.map (
                model:
                if !(builtins.match ".*:.*" model != null) then
                  throw "Ollama model '${model}' must include a tag (e.g., ':latest')."
                else
                  model
              ) models;
            description = "List of ollama models to pull on startup.";
          };
        };
      }
    );
  };

  config =
    lib.mkIf
      (builtins.any (userConfig: userConfig.dev.ollama.enable or false) (
        builtins.attrValues config.custom.users
      ))
      {
        home-manager.users = myLib.mkForEachUsers (user: user.custom.dev.ollama.enable or false) (
          _:
          { myConfig, config, ... }:
          let
            ollamaConfig = myConfig.dev.ollama;
          in
          {
            services.ollama = {
              enable = true;
              package = ollamaConfig.package;
              host = ollamaConfig.host;
            };
            home.persistence."/persist".directories = [
              ".ollama/models"
            ];
            systemd.user.services = {
              ollama-model-loader = {
                Unit = {
                  After = [ "ollama.service" ];
                };

                Service = {
                  Type = "oneshot";
                  TimeoutStartSec = 0;
                  ExecStart = pkgs.writeShellScript "ollama-sync-models" ''
                    OLLAMA_BIN="${config.services.ollama.package}/bin/ollama"

                    ${lib.concatMapStringsSep "\n" (
                      model: "$OLLAMA_BIN pull ${lib.escapeShellArg model}"
                    ) ollamaConfig.loadModels}

                    INSTALLED=$($OLLAMA_BIN list | tail -n +2 | awk '{print $1}' | sort)

                    WANTED=$(cat <<EOF | sort
                    ${lib.concatStringsSep "\n" ollamaConfig.loadModels}
                    EOF
                    )

                    TO_REMOVE=$(comm -23 <(echo "$INSTALLED") <(echo "$WANTED"))

                    for model in $TO_REMOVE; do
                      if [ -n "$model" ]; then
                        echo "Cleaning up obsolete model: $model"
                        $OLLAMA_BIN rm "$model"
                      fi
                    done
                  '';
                };

                Install = {
                  WantedBy = [ "default.target" ];
                };
              };
            };
          }
        );
      };
}
