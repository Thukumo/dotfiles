{ config, lib, ... }:

{
  documentation.nixos.enable = false;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nixpkgs.config.allowUnfree = true;
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = false;

  # Inject each user's custom config into their home-manager module
  # Single source of truth: iterate custom.users only (asserted in common/core/users.nix)
  home-manager.users = lib.mkMerge (
    lib.mapAttrsToList (name: _: {
      ${name}._module.args.myConfig = config.custom.users.${name};
    }) config.custom.users
  );

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
    update = "pushd ${config.users.users."tsukumo".home}/dotfiles/ && sudo nix flake update && popd";
    check = "pushd ${config.users.users."tsukumo".home}/dotfiles/ && nix flake check && popd";
    sl = "nix shell";
  };

  home-manager.sharedModules = [
    {
      home.stateVersion = config.system.stateVersion;
      programs.home-manager.enable = true;
    }
  ];

  home-manager.backupCommand = "rm -rf";
}
