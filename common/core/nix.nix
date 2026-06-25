{
  config,
  lib,
  myLib,
  pkgs,
  ...
}:

{
  documentation.nixos.enable = false;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # https://lix.systems/add-to-config/
  nixpkgs.overlays = [
    (_: prev: {
      inherit (prev.lixPackageSets.stable)
        nixpkgs-review
        nix-eval-jobs
        nix-fast-build
        colmena
        ;
    })
  ];
  nix.package = pkgs.lix;

  nixpkgs.config.allowUnfree = true;
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = false;

  # Inject each user's custom config into their home-manager module
  home-manager.users = lib.mkMerge [
    (lib.mkMerge (
      lib.mapAttrsToList (name: _: {
        ${name}._module.args.myConfig = config.custom.users.${name};
      }) config.custom.users
    ))
    (myLib.mkForEachUsers (u: u.custom.dotfilesPath != null) (
      u:
      { pkgs, ... }:
      {
        home.persistence."/persist".directories = [ u.custom.dotfilesPath ];

        systemd.user.services.git-pull-dotfiles = {
          Unit = {
            Description = "Pull dotfiles repository on login";
            After = [ "network-online.target" ];
          };
          Service = {
            Type = "oneshot";
            ExecStart = "${pkgs.git}/bin/git -C %h/${u.custom.dotfilesPath} pull";
            Restart = "on-failure";
            RestartSec = "30s";
            StartLimitBurst = "10";
            RemainAfterExit = false;
          };
          Install.WantedBy = [ "default.target" ];
        };
      }
    ))
  ];

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

  home-manager.sharedModules = [
    {
      home.stateVersion = config.system.stateVersion;
      programs.home-manager.enable = true;
    }
  ];

  nix.settings = {
    substituters = [
      "https://tsukumo.cachix.org"
    ];
    trusted-public-keys = [
      "tsukumo.cachix.org-1:qkC2tQg2tP1HVH6A45QzRwhFKgry6YPlE9CmBYl/Vmc="
    ];
  };

  home-manager.backupCommand = "rm -rf";
}
