{
  lib,
  pkgs,
  mkForEachUsers,
  ...
}:

{
  config = {
    services = {
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
    };

    services.power-profiles-daemon.enable = lib.mkForce false;

    home-manager.users = mkForEachUsers (user: user.custom.desktop.de == "gnome") (user: {
      imports = [
        ./home.nix
      ];
    });
  };
}
