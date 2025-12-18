{ config, ... }:

{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nixpkgs.config.allowUnfree = true;
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  nix.gc = {
    automatic = true;
    dates = "00:00";
    randomizedDelaySec = "45min";
    options = "--delete-older-than 7d";
  };

  nix.optimise = {
    automatic = true;
    dates = "13:00";
    randomizedDelaySec = "45min";
  };

  environment.shellAliases = {
    rebuild = "sudo nixos-rebuild switch --flake ${config.users.users."tsukumo".home}/dotfiles/";
    update = "pushd ${config.users.users."tsukumo".home}/dotfiles/ && sudo nix flake update && cd -";
    check = "pushd ${config.users.users."tsukumo".home}/dotfiles/ && nix flake check && cd -";
    sl = "nix shell";
  };

  home-manager.sharedModules = [
    {
      home.stateVersion = config.system.stateVersion;
      programs.home-manager.enable = true;
    }
  ];
}
