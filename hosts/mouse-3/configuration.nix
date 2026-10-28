_:

{
  security.tpm2.enable = false;

  services.journald.settings.Journal = {
    Storage = "volatile";
    RuntimeMaxUse = "64M";
    RuntimeKeepFree = "64M";
    MaxRetentionSec = "2days";
  };

  custom = {
    style.plymouth.enable = false;
    network = {
      mycelium.enable = true;
      cloudflare-warp.enable = false;
      ssh-server.enable = true;
    };
    hardware.keyboard.keybind.enable = false;
    security.clamav.realtime.enable = false;
    users."tsukumo" = {
      account.userConfig.linger = true;
      desktop.enable = false;
      dev = {
        podman.enable = true;
        opencode.web.enable = true;
        pi.enable = true;
      };
    };
  };

  # agenix system key (for secrets not tied to a specific user)
  custom.secrets.systemAgeKey.enable = true;

  system.stateVersion = "26.05";
}
