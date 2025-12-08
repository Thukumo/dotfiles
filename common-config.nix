# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, ... }:

{

  # for XDGportal
  environment.pathsToLink = [ "/share/xdg-desktop-portal" "/share/applications" ];


  # for gnome-disk-utility
  services.udisks2.enable = true;
  services.gvfs.enable = true;

  imports = [
  ];
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Bootloader
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    timeout = 0;
  };

  boot.kernel.sysctl."kernel.sysrq" = 1;

  boot.kernelPackages = pkgs.linuxPackages_zen;

  age = {
    secrets = {
      "passwd_tsukumo".file = ./secrets/passwd_tsukumo.age;
      "home-manager_key" = {
        file = ./secrets/home_manager_key.age;
        owner = "tsukumo";
        mode = "400";
      };
    };
  };

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking = {
    networkmanager = {
      enable = true;
      dns = "systemd-resolved";
    };
    nameservers = [
      "2606:4700:4700::1111"
      "2606:4700:4700::1001"
      "1.1.1.1"
      "1.0.0.1"
      "2620:fe::fe"
      "9.9.9.9"
    ];
  };
  services.resolved = {
    enable = true;
    dnssec = "allow-downgrade";
    # dnssec = "true";
    dnsovertls = "opportunistic";
    domains = [ "~." ];
    fallbackDns = [];
  };

  security.rtkit.enable = true;
  # services.pipewire.enable = false;
  # services.pulseaudio = {
  #   enable = true;
  #   package = pkgs.pulseaudioFull;
  # };

  # Set your time zone.
  time.timeZone = "Asia/Tokyo";

  # Select internationalisation properties.
  i18n.defaultLocale = "ja_JP.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ja_JP.UTF-8";
    LC_IDENTIFICATION = "ja_JP.UTF-8";
    LC_MEASUREMENT = "ja_JP.UTF-8";
    LC_MONETARY = "ja_JP.UTF-8";
    LC_NAME = "ja_JP.UTF-8";
    LC_NUMERIC = "ja_JP.UTF-8";
    LC_PAPER = "ja_JP.UTF-8";
    LC_TELEPHONE = "ja_JP.UTF-8";
    LC_TIME = "ja_JP.UTF-8";
  };

  users.mutableUsers = false;
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.tsukumo = {
    isNormalUser = true;
    description = "tsukumo";
    hashedPasswordFile = config.age.secrets."passwd_tsukumo".path;
    extraGroups = [ "networkmanager" "wheel" ];
  };
  home-manager.users.tsukumo = {
    imports = [
      ./home-manager/home.nix
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  # Enable automatic login for the user.
  # services.getty.autologinUser = "tsukumo";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    #  wget
    inputs.ragenix.packages."${stdenv.hostPlatform.system}".default
  ];

  environment.shellAliases = {
    rebuild = "sudo nixos-rebuild switch --flake ${config.users.users.tsukumo.home}/dotfiles/";
    update = "pushd ${config.users.users.tsukumo.home}/dotfiles/ && sudo nix flake update && cd -";
    check =  "pushd ${config.users.users.tsukumo.home}/dotfiles/ && nix flake check && cd -";
  };
  programs.fish.enable = true;
  users.defaultUserShell = pkgs.fish;

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

  powerManagement.enable = true;
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_performance";
    };
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether
  # networking.firewall.enable = false;

}
