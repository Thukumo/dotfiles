{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    activate-linux
  ];
  programs.niri.settings.spawn-at-startup = [ { argv = [ "bash" "-c" "LANG=C activate-linux -d" ]; } ];
}

