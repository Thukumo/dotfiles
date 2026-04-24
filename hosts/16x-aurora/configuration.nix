# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs, config, ... }:

{
  # for wivrn
  # networking.networkmanager.wifi.powersave = false;
  custom.users."tsukumo" = {
    network.globalProtect.enable = true;
    network.dlna = {
      enable = false;
      mediaDirs = [ "V,Documents/mov" ];
    };
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
        gnome-disk-utility.enable = false;
        rquickshare.enable = false;
        thunar.enable = false;
        steam.enable = true;
        prismLauncher.enable = true;
        localsend.enable = true;
        blender.enable = true;
        mpv = {
          enable = true;
          gpu-api = "vulkan";
        };
      };
      vr.enable = true;
    };
    dev = {
      ollama = {
        enable = true;
        package = pkgs.ollama-cuda;
        loadModels = [
          # "gemma4:e4b"
        ];
      };
      opencode = {
        enable = true;
        models = config.custom.users."tsukumo".dev.ollama.loadModels;
      };
      aider.enable = false;
      antigravity.enable = true;
      unityhub.enable = true;
    };
  };
  services.open-webui.enable = false;
  custom.network.cloudflare-warp.enable = true;

  custom.hardware.keybind.deviceIds = [ "0001:0001" ];

  # agenix system key (for secrets not tied to a specific user)
  custom.secrets.extraIdentityPaths = [ "/etc/age/key.txt" ];
  environment.persistence."/persist".files = [
    "/etc/age/key.txt"
  ];

  custom.hardware.disk = {
    disko = {
      diskName = "/dev/disk/by-id/nvme-PM9C1b_Samsung_1024GB_______S7UKNF1Y956462";
      swapSize = "70G";
    };
    beesd.hashTableSizeMB = 2048;
  };

  custom.hardware.gpu.nvidia.enable = true;
  hardware.nvidia = {
    powerManagement.finegrained = true;
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # services.pipewire.enable = false;
  # services.pulseaudio = {
  #   enable = true;
  #   package = pkgs.pulseaudioFull;
  # };

  console.keyMap = "jp106";
  services.xserver.xkb = {
    layout = "jp106";
    variant = "";
  };

  hardware.bluetooth.enable = true;
  system.stateVersion = "26.05";

}
