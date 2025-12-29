{
  lib,
  config,
  mkForEachUsers,
  ...
}:

{
  options.users.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.custom.dev.podman = {
          enable = lib.mkEnableOption "podman";
        };
      }
    );
  };

  config =
    lib.mkIf
      (builtins.any (user: user.custom.dev.podman.enable) (builtins.attrValues config.users.users))
      {
        virtualisation = {
          containers.enable = true;
          podman = {
            enable = true;
            dockerCompat = true;
            defaultNetwork.settings.dns_enabled = true;
          };
        };

        home-manager.users = mkForEachUsers (user: user.custom.dev.podman.enable) (
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
