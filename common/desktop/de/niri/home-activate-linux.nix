{
  pkgs,
  myConfig,
  lib,
  ...
}:

{
  programs.niri.settings.spawn-at-startup = lib.mkIf myConfig.desktop.activate-linux.enable [
    {
      argv = [
        "bash"
        "-c"
        "LANG=C ${pkgs.activate-linux}/bin/activate-linux -d"
      ];
    }
  ];
}
