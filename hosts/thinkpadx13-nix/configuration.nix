# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs, ... }:

{

  # custom.desktop.steam.enable = true;

  imports = [
    ./hardware.nix # 再インストール時に消す
  ];

  zramSwap = {
    enable = true;
    memoryPercent = 200;
  };

  # agenix key
  custom = {
    secrets.secretKey = "/etc/age/key.txt";
    disko = {
      # enable = true; # 後で再インストールするときに有効にする
      diskName = "/dev/disk/by-id/nvme-SKHynix_HFS256GD9TNI-L2B0B_NY06N11541090762N";
      swapSize = "10G";
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

  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      # dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  # Enable automatic login for the user.
  # services.getty.autologinUser = "tsukumo";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    #  wget
    podman-compose
  ];

  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings = {
        main = {
          capslock = "overload(meta, tab)";
          shift = "overload(shift, esc)";
          muhenkan = "home";
          henkan = "end";
          katakanahiragana = "end";
          space = "overload(nav, space)";
          tab = "/";
        };
        nav = {
          h = "left";
          k = "up";
          j = "down";
          l = "right";
        };
        "nav+meta" = {
          h = "home";
          l = "end";
        };
      };
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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}
