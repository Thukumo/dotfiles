{ pkgs, ... }:

{
  home.packages = with pkgs; [
    podman-tui
  ];
  home.shellAliases = {
    docker = "podman";
  };
}
