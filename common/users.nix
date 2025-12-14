{ config, pkgs, ... }:

{
  users.mutableUsers = false;

  users.users."tsukumo" = {
    isNormalUser = true;
    hashedPasswordFile = config.age.secrets."passwd_tsukumo".path;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.fish;
  };
  # for shell
  programs.fish.enable = true;

  home-manager.users."tsukumo" = {
    imports = [
      ./home-manager
    ];
  };

  security.sudo.wheelNeedsPassword = false;
}
