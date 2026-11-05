# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  myLib,
  config,
  ...
}:

{
  custom.hardware.secure-boot.enable = true;
  # 7GB RAM; 25% (1.75GB) hit the zswap pool limit and wrote back to disk
  custom.hardware.tune.zswap.maxPoolPercent = 40;
  custom.network.wifi.enable = true;
  # # nanoKVM
  # services.udev.extraRules = ''
  #   SUBSYSTEM=="usb", ATTR{idVendor}=="345f", ATTR{idProduct}=="2131", MODE="0666", GROUP="plugdev"
  #   SUBSYSTEM=="tty", ATTRS{idVendor}=="345f", ATTRS{idProduct}=="2131", MODE="0666", GROUP="dialout"
  # '';
  # users.users.tsukumo.extraGroups = [
  #   "dialout"
  #   "plugdev"
  # ];
  boot.kernelParams = [
    "mem_encrypt=on"

    "pcie_aspm=force"
    "pcie_aspm.policy=powersave"
    "amdgpu.aspm=1"
  ];
  systemd.tmpfiles.rules = [
    "w /sys/class/power_supply/BAT0/charge_control_start_threshold - - - - 75"
    "w /sys/class/power_supply/BAT0/charge_control_end_threshold - - - - 80"
  ];

  home-manager.users = myLib.mkForEachUsers config (_: true) (_: {
    programs.niri.settings.input.touchpad.enable = false;
  });

  custom = {
    network.mycelium.enable = true;
    network.cloudflare-warp.enable = true;
    users."tsukumo" = {
      network.dlna = {
        enable = true;
        mediaDirs = [ "V,Documents/mov" ];
      };
      network.globalProtect.enable = true;
      desktop = {
        apps = {
          discord.enable = true;
          google-chrome.enable = true;
          mattermost-desktop.enable = true;
          onlyoffice.enable = true;
          zoom.enable = true;
          gnome-disk-utility.enable = true;
          thunar.enable = true;
          steam.enable = true;
          prismLauncher.enable = true;
          localsend.enable = true;
          blender.enable = true;
          sidra.enable = true;
        };
        voice-input = {
          enable = true;
          language = "ja";
        };
      };
      dev = {
        gns3.enable = true;
        unityhub.enable = true;
        pi.enable = true;
        llama = {
          enable = true;
          # 内蔵Radeon (RADV RENOIR) でVulkanオフロードを試す
          vulkanSupport = true;
          # 7GB RAMなのでmlockせずページキャッシュに任せる
          mlock = false;
          models = [
            {
              name = "LFM3-1.7B";
              repoId = "LiquidAI/LFM3-1.7B-GGUF";
              file = "LFM3-1.7B-Q4_K_M.gguf";
              # LFM3はnixpkgs 0.6.0 / Prism forkに未収録
              backend = "upstream";
              gpuLayers = 99;
              contextLength = 32768;
              extraArgs = [
                "--jinja"
                "-np"
                "1"
                "--temp"
                "0.1"
                "--top-p"
                "1.0"
                "--top-k"
                "50"
                "--min-p"
                "0.0"
                "--repeat-penalty"
                "1.1"
              ];
            }
          ];
        };
      };
    };

    hardware.keyboard.keybind.deviceIds = [ "0001:0001" ];
  };

  imports = [
    ./hardware.nix
  ];

  # agenix system key (for secrets not tied to a specific user)
  custom.secrets.systemAgeKey.enable = true;

  custom.hardware.disk = {
    btrfs-autoScrub.enable = true;
    beesd = {
      hashTableSizeMB = 256;
    };
    # 後で再インストールするときに有効にする:
    # disko = {
    #   diskName = "/dev/disk/by-id/nvme-SKHynix_HFS256GD9TNI-L2B0B_NY06N11541090762N";
    #   swapSize = "10G";
    # };
    disko = null;
    snapshot.enable = true;
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
