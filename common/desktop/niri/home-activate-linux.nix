{ pkgs, ... }:

{
  programs.niri.settings.spawn-at-startup = [
    {
      argv = [
        "bash"
        "-c"
        "LANG=C ${pkgs.activate-linux}/bin/activate-linux -d"
      ];
    }
  ];
}
