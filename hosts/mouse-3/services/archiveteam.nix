_:

{
  # https://stepney141.hatenablog.com/entry/2025/02/17/182148
  home-manager.users."tsukumo".services.podman.containers.archiveteam = {
    image = "atdr.meo.ws/archiveteam/warrior-dockerfile";
    ports = [ "127.0.0.1:8080:8001" ];
    autoUpdate = "registry";
    environment = {
      "DOWNLOADER" = "tsukumo";
      "SELECTED_PROJECT" = "auto";
      "CONCURRENT_ITEMS" = 2;
    };
    extraPodmanArgs = [
      "--tmpfs"
      "/home/warrior/data/projects"
    ];
    extraConfig.Service = {
      # 実はsystemd側でAlwaysにされるから書く意味ない(明示したいだけ)
      Restart = "always";
      TimeoutStopSec = 300;
      KillSignal = "SIGINT";
    };
  };
}
