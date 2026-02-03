{
  lib,
  config,
  myLib,
  ...
}:

{
  options.custom.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.dev.podman = {
          enable = lib.mkEnableOption "podman";
        };
      }
    );
  };

  config =
    lib.mkIf
      (builtins.any (userConfig: userConfig.dev.podman.enable or false) (builtins.attrValues config.custom.users))
      {
        virtualisation = {
          containers.enable = true;
          podman = {
            enable = true;
            dockerCompat = true;
            defaultNetwork.settings.dns_enabled = true;
          };
        };

        home-manager.users = myLib.mkForEachUsers (user: user.custom.dev.podman.enable or false) (
          user:
          { pkgs, ... }:
          {
            home.packages = with pkgs; [
              podman-tui
              podman-compose
            ];
            home.shellAliases = {
              docker = "podman";
            };
          }
        );
      };
}
