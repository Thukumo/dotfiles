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
        bottles.enable = true;
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
            repoId = "prism-ml/Ternary-Bonsai-2-27B-gguf";
            file = "Ternary-Bonsai-2-27B-PTQ1_0.gguf";
            contextLength = 65536;
            # 8GB VRAM実測: -ngl autoだと見積りゲートで層がCPUに落ちる (64kで3tok/s) ため
            # -ngl 99で全層GPU固定。c96baf4実測: 短ctx PP473/TG27、49k depth PP305/TG23
            # -np 1、小batch、Q4_0 KVもVRAMに収めるため必須 (64kで約6.9GB使用)
            # ngram系specは効果なしのため不使用 (モジュール側で--spec-defaultは付与しない)
            # MTPは下のmtp-48kエントリで実測済み。DSparkはdrafter待ち
            gpuLayers = 99;
            # 4slotだとVRAM溢れでCPU fallback (0.7tok/s) するため np1+小batch+Q4_0 KVでVRAMに収める
            # q8_0 Kは64kで初回リクエスト時にOOMするためq4_0固定
            # NOTE: このエントリにmmproj入れるな。Bonsai 2はGPU実行されず3tok/sに落ちる (実測)。
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
          {
            # 旧pin (2459f68, depth3) 実測: MTP無し=PP422/TG27 → MTP=PP357/TG57-78 (acceptance 60-66%)
            # c96baf4実測 (depth2デフォルト): 短ctx TG48.9 (acceptance 66%)。depth3は48k/8GBでOOMするため指定しない
            # モデルはコミュニティ製 (sudoingx) のPTQ1_0+MTPリーン版。64kだとVRAMに収らないため48k
            name = "Ternary-Bonsai-2-27B-PTQ1_0-mtp-48k";
            repoId = "sudoingx/Ternary-Bonsai-2-27B-PTQ1_0-MTP-GGUF";
            file = "Ternary-Bonsai-2-27B-PTQ1_0-mtp-lean.gguf";
            contextLength = 49152;
            gpuLayers = 99;
            cacheTypeK = "q4_0";
            cacheTypeV = "q4_0";
            specType = [ "draft-mtp" ];
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
          {
            name = "LFM3-VL-2B";
            repoId = "LiquidAI/LFM3-VL-2B-GGUF";
            file = "LFM3-VL-2B-Q4_K_M.gguf";
            mmproj = {
              repoId = "LiquidAI/LFM3-VL-2B-GGUF";
              file = "mmproj-LFM3-VL-2B-F16.gguf";
            };
            # nixpkgs 0.6.0 / Prism fork には LFM3 が無いので upstream master を使う
            backend = "upstream";
            gpuLayers = 99;
            contextLength = 128000;
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
          {
            name = "LFM3-1.7B";
            repoId = "LiquidAI/LFM3-1.7B-GGUF";
            file = "LFM3-1.7B-Q4_K_M.gguf";
            backend = "upstream";
            gpuLayers = 99;
            contextLength = 256000;
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
      pi.enable = true;
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

  # auto-cpufreq's performance governor makes intel_pstate reject EPP writes
  # (EBUSY), and its turbo=auto left no_turbo=1 (CPU capped at 2.4GHz base).
  # Disable it here; use intel_pstate powersave with turbo enabled.
  custom.hardware.tune.auto-cpufreq.enable = false;
  powerManagement.cpuFreqGovernor = "powersave";

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
