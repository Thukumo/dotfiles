# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, ... }:

{
  custom.hardware.secure-boot.enable = true;
  # for wivrn
  # networking.networkmanager.wifi.powersave = false;
  custom.users."tsukumo" = {
    network = {
      globalProtect.enable = true;
      sstp.enable = true;
    };
    network.dlna = {
      enable = false;
      mediaDirs = [ "V,Documents/mov" ];
    };
    desktop = {
      enable = true;
      de = "niri";
      launcher = "fuzzel";
      terminal = "foot";
      winapps.enable = true;
      ime = "skk";
      apps = {
        chromium.enable = true;
        discord.enable = true;
        google-chrome.enable = true;
        mattermost-desktop.enable = true;
        libreoffice.enable = true;
        zoom.enable = true;
        gnome-disk-utility.enable = false;
        osu.enable = true;
        rquickshare.enable = false;
        thunar.enable = false;
        steam.enable = true;
        prismLauncher.enable = true;
        localsend.enable = true;
        blender.enable = true;
        slack.enable = true;
        sidra.enable = true;
        mpv = {
          enable = true;
          gpu-api = "vulkan";
        };
      };
      vr.enable = true;
    };
    dev = {
      llama = {
        enable = true;
        cudaSupport = true;
        models = [
          {
            repoId = "unsloth/Qwen3.6-35B-A3B-MTP-GGUF";
            file = "Qwen3.6-35B-A3B-UD-Q4_K_M.gguf";
            specType = [ "draft-mtp" ];
            extraArgs = [ "--cpu-moe" ];
          }
          {
            repoId = "google/gemma-4-26B-A4B-it-qat-q4_0-gguf";
            file = "gemma-4-26B_q4_0-it.gguf";
          }
          rec {
            repoId = "ggml-org/gemma-4-12B-it-GGUF";
            file = "gemma-4-12B-it-Q4_K_M.gguf";
            specType = [ "draft-mtp" ];
            contextLength = 64000;
            draft = {
              inherit repoId;
              file = "mtp-gemma-4-12B-it-Q4_0.gguf";
            };
          }
          rec {
            repoId = "ggml-org/gemma-4-E4B-it-GGUF";
            file = "gemma-4-E4B-it-Q4_0.gguf";
            specType = [ "draft-mtp" ];
            draft = {
              inherit repoId;
              file = "mtp-gemma-4-E4B-it-Q4_0.gguf";
            };
          }
        ];
      };
      opencode = {
        enable = true;
        models = map (m: m.name) config.custom.users."tsukumo".dev.llama.models;
      };
      antigravity.enable = true;
      unityhub.enable = true;
    };
  };
  # 壊れていそう
  # services.open-webui.enable = true;
  custom.network.cloudflare-warp.enable = true;

  custom.hardware.keyboard.keybind.deviceIds = [ "0001:0001" ];

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

  # hardware.enableRedistributableFirmware = true;
  # boot.kernelModules = [ "mt7925e" ];

  hardware.bluetooth.enable = true;
  system.stateVersion = "26.05";
}
