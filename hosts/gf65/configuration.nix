# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ lib, pkgs, ... }:

{

  custom.desktop.apps = {
    steam.enable = true;
    chromium.enable = false;
    discord.enable = false;
    google-chrome.enable = false;
    mattermost-desktop.enable = false;
    libreoffice.enable = false;
    zoom.enable = false;
    gnome-disk-utility.enable = false;
    rquickshare.enable = false;
    thunar.enable = false;
  };

  # 一時的に人に貸すので、ゲストアカウント的なものを作成
  users.users."tya" = {
    isNormalUser = true;
    password = "tya";
  };
  home-manager.users."tya" = {
    home.persistence."/persist/home/tya" = {
      allowOther = true;
      directories = [
       ".local/share/Steam"
      ".local/share/applications"
    ];
  };
    home.stateVersion = "25.05";
  };
  services.greetd.settings = {
    default_session.user = lib.mkForce "tya";
    initial_session.user = lib.mkForce "tya";
  };

  imports = [
  ];

  zramSwap = {
    enable = true;
    memoryPercent = 100;
  };

  # agenix key
  custom = {
    secrets.secretKey = "/etc/age/key.txt";
    disko = {
      enable = true;
      diskName = "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_2TB_S7HENJ0Y235481M";
      swapSize = "70G";
    };
  };

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # services.pipewire.enable = false;
  # services.pulseaudio = {
  #   enable = true;
  #   package = pkgs.pulseaudioFull;
  # };

  console.keyMap = "jp106";
  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "jp106";
    variant = "";
  };

  # Enable automatic login for the user.
  # services.getty.autologinUser = "tsukumo";

  # List packages installed in system profile. To search, run:
  # $ nix search wget

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
