{
  config,
  lib,
  myLib,
  ...
}:

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

        home.shellAliases = {
          rebuild = "sudo nixos-rebuild switch --flake $HOME/${u.custom.dotfilesPath}/";
          update = "pushd $HOME/${u.custom.dotfilesPath}/ && sudo nix flake update && popd";
          check = "pushd $HOME/${u.custom.dotfilesPath}/ && nix flake check && popd";
        };
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

  home-manager.backupCommand = "rm -rf";
}
