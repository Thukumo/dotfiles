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
            systemd.user.services = lib.mkIf (ollamaConfig.loadModels != [ ]) {
              ollama-model-loader = {
                Unit = {
                  After = [ "ollama.service" ];
                  Requires = [ "ollama.service" ];
                };

                Service = {
                  Type = "simple";
                  TimeoutStartSec = 0;
                  ExecStart = pkgs.writeShellScript "ollama-pull-models" ''
                    ${lib.concatMapStringsSep "\n" (
                      model: "${config.services.ollama.package}/bin/ollama pull ${lib.escapeShellArg model}"
                    ) ollamaConfig.loadModels}
                  '';
                  RemainAfterExit = true;
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
