{ pkgs, config, osConfig, lib, ... }:

{
  programs.niri.settings.spawn-at-startup = lib.mkIf osConfig.users.users.${config.home.username}.custom.desktop.activate-linux.enable [
    {
      argv = [
        "bash"
        "-c"
        "LANG=C ${pkgs.activate-linux}/bin/activate-linux -d"
      ];
    }
  ];
}
