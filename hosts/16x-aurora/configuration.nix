# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  security.sudo-rs.wheelNeedsPassword = false;
  custom.hardware.secure-boot.enable = true;
  custom.security.gaze = {
    enable = true;
    # このマシンの赤外線カメラ (Realtek Integrated_Webcam_FHD, USB 0bda:558b) は
    # RGB/IR を同時ストリーミングできない。rgb/ir 共に同じ VID:PID で、
    # カラーノード / IR ノードに自動解決される。
    rgb = "";
    ir = "usb:0bda:558b";
    darkLumaThreshold = 10;
    securityLevel = "maximum";
  };
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
      mimeBrowser = "chromium";
      browser = "librewolf";
      launcher = "fuzzel";
      terminal = "foot";
      winapps.enable = false;
      ime = "skk";
      apps = {
        discord.enable = true;
        google-chrome.enable = true;
        mattermost-desktop.enable = true;
        onlyoffice.enable = true;
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
      voice-input = {
        enable = true;
        backend = "whisper-cpp";
        cudaSupport = true;
        language = "ja";
      };
    };
    dev = {
      llama = {
        enable = true;
        cudaSupport = true;
        prismFork = true;
        # fimModel = "qwen2.5-coder-7b";
        models = [
          {
            repoId = "prism-ml/Bonsai-27B-gguf";
            file = "Bonsai-27B-Q1_0.gguf";
            contextLength = 32768;
          }
          {
            repoId = "prism-ml/Ternary-Bonsai-2-27B-gguf";
            file = "Ternary-Bonsai-2-27B-PTQ1_0.gguf";
            contextLength = 65536;
            # 8GB VRAM実測: -ngl autoだと見積りゲートで層がCPUに落ちる (64kで3tok/s) ため
            # -ngl 99で全層GPU固定 (実測 PP22/TG21 tok/s、警告なし)
            # -np 1、小batch、Q4_0 KVもVRAMに収めるため必須
            # ngram系specは全種実測で効果なし (TG 20.7-20.9で横並び、ngram-cacheは微減) のため不使用。
            # DSpark/MTP drafter待ち
            gpuLayers = 99;
            # 8GB VRAM実測: 4slotだとVRAM溢れでCPU fallback (0.7tok/s) するため
            # np1+小batch+Q4_0 KVでVRAMに収める (実測 PP17/TG21 tok/s)
            # NOTE: このエントリにmmproj入れるな。Bonsai 2はGPU実行されず3tok/sに落ちる (実測)。
            # 画像入力は無印Q1_0エントリ (mmproj付き・18tok/s) を使うこと
            cacheTypeK = "q4_0";
            cacheTypeV = "q4_0";
            extraArgs = [
              "-np"
              "1"
              "-ub"
              "128"
              "-b"
              "256"
            ];
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
          {
            repoId = "InternScience/Agents-A1-4B-Q4_K_M-GGUF";
            file = "Agents-A1-4B-Q4_K_M.gguf";
          }
        ];
      };
      opencode = {
        enable = true;
      };
      antigravity.enable = true;
      unityhub.enable = true;
    };
  };

  custom.network = {
    wifi.enable = true;
    cloudflare-warp.enable = true;
  };

  networking.dhcpcd.extraConfig = ''
    metric 700
  '';

  custom.hardware.keyboard.keybind.deviceIds = [ "0001:0001" ];

  # agenix system key (for secrets not tied to a specific user)
  custom.secrets.systemAgeKey.enable = true;

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

  # spd5118 (DDR5 SPD hub temp sensor) causes random system freezes
  # on Arrow Lake-HX (Alienware 16X) due to I2C/SMBus communication
  # failures (spd5118_resume: error -6). Blacklist to prevent lockups.
  boot.blacklistedKernelModules = [ "spd5118" ];

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # services.pipewire.enable = false;
  # services.pulseaudio = {
  #   enable = true;
  #   package = pkgs.pulseaudioFull;
  # };

  hardware.bluetooth.enable = true;
  system.stateVersion = "26.05";
}
