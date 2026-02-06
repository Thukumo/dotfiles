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
          { myConfig, ... }:
          {
            services.ollama = myConfig.dev.ollama // {
              enable = true;
              environmentVariables = {
                OLLAMA_CONTEXT_LENGTH = "131072";
              };
            };
            home.persistence."/persist".directories = [
              ".ollama/models"
            ];
          }
        );
      };
}
