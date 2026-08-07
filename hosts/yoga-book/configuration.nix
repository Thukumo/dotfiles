{ myLib, config, ... }:

{
  security.tpm2.enable = false;

  hardware.yogabook = {
    enable = true;
    keyboardLayout = "jp106";
  };
  services.keyd.keyboards.default.settings.main = {
    fn = "leftcontrol";
    leftcontrol = "fn";
  };

  custom = {
    security.clamav = {
      enable = false;
      realtime.enable = false;
    };
    network = {
      mycelium.enable = true;
      cloudflare-warp.enable = true;
    };
    users."tsukumo" = {
      network.globalProtect.enable = true;
      desktop = {
        enable = true;
        de = "niri";
        mimeBrowser = "chromium";
        browser = "librewolf";
        launcher = "fuzzel";
        terminal = "foot";
        ime = "skk";
        apps = {
          google-chrome.enable = true;
          mattermost-desktop.enable = true;
          onlyoffice.enable = true;
        };
      };
    };
  };

  custom.hardware.keyboard.keybind.deviceIds = [ "18d1:00ff" ];

  custom.secrets.extraIdentityPaths = [ "/etc/age/key.txt" ];
  environment.persistence."/persist".directories = [
    "/etc/age"
  ];

  custom.hardware.disk = {
    beesd.hashTableSizeMB = 256;
    disko = {
      enable = true;
      diskName = "/dev/disk/by-id/mmc-064G70_0x432c5b54";
      swapSize = "6G";
    };
  };

  home-manager.users = myLib.mkForEachUsers config (_: true) (_: {
    programs.niri.settings.input = {
      touch = {
        map-to-output = "DSI-1";
      };
      tablet = {
        map-to-output = "DSI-1";
        # NUR側で定義されたudevの回転ルール（0 1 0 -1 0 1）と、Niriの自動出力回転機能（270° CCW）が
        # 二重適用されるのを防ぐため、ここでは明示的に単位行列（identity）に上書きして自動回転のみを活かします。
        calibration-matrix = [
          [
            1.0
            0.0
            0.0
          ]
          [
            0.0
            1.0
            0.0
          ]
        ];
      };
    };
  });

  system.stateVersion = "26.05";
}
