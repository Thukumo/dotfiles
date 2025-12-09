{ config, ... }:

{
  users.mutableUsers = false;

  users.users.tsukumo = {
    isNormalUser = true;
    description = "tsukumo";
    hashedPasswordFile = config.age.secrets."passwd_tsukumo".path;
    extraGroups = [ "networkmanager" "wheel" ];
  };

  home-manager.users.tsukumo = {
    imports = [
      ../home-manager/home.nix
    ];
  };

  security.sudo.wheelNeedsPassword = false;
}
