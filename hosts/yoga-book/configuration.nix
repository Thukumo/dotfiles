_:

{
  hardware.yogabook.enable = true;

  custom = {
    network = {
      mycelium.enable = true;
      cloudflare-warp.enable = true;
    };
    users."tsukumo" = {
      network.globalProtect.enable = true;
      desktop = {
        enable = true;
        de = "niri";
        launcher = "fuzzel";
        terminal = "foot";
        ime = "skk";
        apps = {
          chromium.enable = true;
          google-chrome.enable = true;
          mattermost-desktop.enable = true;
          libreoffice.enable = true;
        };
      };
    };
  };

  custom.hardware.keyboard.keybind.deviceIds = [ "0001:0001" ];

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

  console.keyMap = "jp106";
  services.xserver.xkb = {
    layout = "jp106";
    variant = "";
  };

  system.stateVersion = "26.05";
}
