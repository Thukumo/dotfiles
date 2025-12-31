{
  lib,
  pkgs,
  mkForEachUsers,
  ...
}:

{
  config = {
    services.xserver = {
      enable = true;
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
    };

    home-manager.users = mkForEachUsers (user: user.custom.desktop.de == "gnome") (user: {
      imports = [
        ./home.nix
      ];
    });
  };
}
