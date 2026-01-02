{
  lib,
  config,
  pkgs,
  mkForEachUsers,
  ...
}:
{
  options.users.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.custom.dev.ollama = {
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

  config = lib.mkIf
    (builtins.any (user: user.custom.dev.ollama.enable) (builtins.attrValues config.users.users))
    {
      home-manager.users = mkForEachUsers (user: user.custom.dev.ollama.enable) (
        user:
        { ... }:
        let
          cfg = user.custom.dev.ollama;
        in
        {
          services.ollama = {
            enable = true;
            package = cfg.package;
            host = cfg.host;
          };
        }
      );
    };
}