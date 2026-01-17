# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ mkForEachUsers, ... }:

{

  home-manager.users = mkForEachUsers (_: true) (_: {
    programs.niri.settings.input.touchpad.enable = false;
  });

  users.users."tsukumo".custom = {
    network.globalProtect.enable = true;
    desktop = {
      enable = true;
      de = "niri";
      launcher = "fuzzel";
      terminal = "foot";
      ime = "skk";
      apps = {
        chromium.enable = true;
        discord.enable = true;
        google-chrome.enable = true;
        mattermost-desktop.enable = true;
        libreoffice.enable = true;
        zoom.enable = true;
        gnome-disk-utility.enable = true;
        rquickshare.enable = true;
        thunar.enable = true;
        steam.enable = true;
        qutebrowser.enable = true;
      };
    };
  };
  custom.desktop.sunshine.enable = false;

  custom.keybind.deviceIds = [ "0001:0001" ]; # Internal keyboard only

  imports = [
    ./hardware.nix # 再インストール時に消す
  ];

  custom.tune.earlyoom.enable = true;

  # agenix system key (for secrets not tied to a specific user)
  custom.secrets.extraIdentityPaths = [ "/etc/age/key.txt" ];
  environment.persistence."/persist".directories = [
    "/etc/age"
  ];

  custom = {
    disk = {
      disko = {
        enable = false; # 後で再インストールするときに有効にする
        diskName = "/dev/disk/by-id/nvme-SKHynix_HFS256GD9TNI-L2B0B_NY06N11541090762N";
        swapSize = "10G";
      };
      snapshot.enable = true;
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
