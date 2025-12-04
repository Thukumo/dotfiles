# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    # ./hardware-configuration.nix
    ./hardware.nix
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

  zramSwap = {
    enable = true;
    memoryPercent = 200;
  };

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/etc/NetworkManager/system-connections"
      "/var/lib/NetworkManager/system-connections"
      "/var/lib/nixos"
      "/var/lib/bluetooth"
      "/etc/age"
      "/var/log"
    ];
    files = [ "/etc/machine-id" ];
  };
  # for "home-manager" impermanence
  programs.fuse.userAllowOther = true;

  age = {
    identityPaths = [ "/persist/etc/age/key.txt" ];
    secrets = {
      "passwd_tsukumo" = {
        file = ./secrets/passwd_tsukumo.age;
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
      connectionConfig = {
        "ipv4.ignore-auto-dns" = true;
        "ipv6.ignore-auto-dns" = true;
      };
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

  # services.xserver.exportConfiguration = true;

  console.keyMap = "jp106";
  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "jp106";
    variant = "";
  };

  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      # dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  # for XDGportal
  environment.pathsToLink = [ "/share/xdg-desktop-portal" "/share/applications" ];

  users.mutableUsers = false;
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.tsukumo = {
    isNormalUser = true;
    description = "tsukumo";
    hashedPasswordFile = config.age.secrets."passwd_tsukumo".path;
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
  };

  security.sudo.wheelNeedsPassword = false;
  home-manager.users.tsukumo = {
    imports = [
      ./home-manager/home.nix
    ];
  };


  # Enable automatic login for the user.
  # services.getty.autologinUser = "tsukumo";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    #  wget
    podman-compose
    inputs.ragenix.packages."${stdenv.hostPlatform.system}".default
  ];

  # for gnome-disk-utility
  services.udisks2.enable = true;
  services.gvfs.enable = true;

  environment.shellAliases = {
    rebuild = "sudo nixos-rebuild switch --flake ${config.users.users.tsukumo.home}/dotfiles/";
    update = "pushd ${config.users.users.tsukumo.home}/dotfiles/ && sudo nix flake update && cd -";
    clean = "nix-collect-garbage --delete-older-than 7d";
    docker = "podman";
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
        # command = "${config.home-manager.users.tsukumo.wayland.windowManager.sway.package}/bin/sway";
        command = "${config.home-manager.users.tsukumo.programs.niri.package}/bin/niri-session";
        user = "tsukumo";
      };
      initial_session = default_session;
    };
  };

  powerManagement.enable = true;
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      # CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_SCALING_GOVERNOR_ON_BAT = "balence_performance";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      # CPU_ENERGY_PERF_POLICY_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balence_performance";
    };
  };

  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings = {
        main = {
          capslock = "overload(meta, esc)";
          shift = "overload(shift, tab)";
          muhenkan = "home";
          henkan = "end";
          katakanahiragana = "end";
          space = "overload(nav, space)";
          tab = "/";
        } // (lib.genAttrs (map toString (lib.range 1 9)) (n: "S-${n}"));
        shift = {
        } // lib.genAttrs (map toString (lib.range 1 9)) (n: "${n}");
        meta = lib.genAttrs (map toString (lib.range 1 9)) (n: "M-${n}");
        "meta+shift" = lib.genAttrs (map toString (lib.range 1 9)) (n: "MS-${n}");
        nav = {
          h = "left";
          k = "up";
          j= "down";
          l = "right";
        };
        "nav+meta" = {
          h = "home";
          l = "end";
        };
      };
    };
  };

  # enable mDNS for rQuickShare
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}
