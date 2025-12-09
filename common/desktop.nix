{ config, pkgs, ... }:

{
  environment.pathsToLink = [ "/share/xdg-desktop-portal" "/share/applications" ];

  services.udisks2.enable = true;
  services.gvfs.enable = true;

  security.rtkit.enable = true;

  fonts.packages = with pkgs; [
    nerd-fonts.adwaita-mono
    ipafont
  ];

  security.polkit.enable = true;

  services.greetd = {
    enable = true;
    settings = rec {
      default_session = {
        command = "${config.home-manager.users.tsukumo.programs.niri.package}/bin/niri-session";
        user = "tsukumo";
      };
      initial_session = default_session;
    };
  };
}
