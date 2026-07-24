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
      (builtins.any (
        userConfig: (userConfig.dev.podman.enable or false) || (userConfig.desktop.winapps.enable or false)
      ) (builtins.attrValues config.custom.users))
      {
        virtualisation = {
          containers.enable = true;
          podman = {
            enable = true;
            dockerCompat = true;
            dockerSocket.enable = true;
            defaultNetwork.settings.dns_enabled = true;
            autoPrune.enable = true;
          };
        };

        home-manager.users =
          myLib.mkForEachUsers
            (user: (user.custom.dev.podman.enable or false) || (user.custom.desktop.winapps.enable or false))
            (
              _user:
              { pkgs, ... }:
              {
                home.packages = with pkgs; [
                  podman-compose
                ];
                home.shellAliases = {
                  docker = "podman";
                };
                # なんかvirtualisation.podmanに依存しているっぽいので、virtualisation〜も要る
                services.podman = {
                  enable = true;
                  enableTypeChecks = true;
                  autoUpdate.onCalendar = "daily";
                };
                home.persistence."/persist".directories = [
                  ".local/share/containers"
                ];
              }
            );
      };
}
