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
