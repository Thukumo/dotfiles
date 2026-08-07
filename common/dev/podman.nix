{
  lib,
  config,
  myLib,
  ...
}:

{
  options.custom.users = myLib.mkUserOption {
    options.dev.podman = {
      enable = lib.mkEnableOption "podman";
    };
  };

  config =
    lib.mkIf (myLib.anyUser config (user: user.dev.podman.enable || user.desktop.winapps.enable))
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
          myLib.mkForEachUsers config
            (user: user.custom.dev.podman.enable || user.custom.desktop.winapps.enable)
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
