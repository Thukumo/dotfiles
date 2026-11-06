{ config, ... }:

{
  security.tpm2.enable = false;

  security.sudo-rs.wheelNeedsPassword = true;

  # Headless recovery: a boot with failed units is not marked good, and
  # systemd-boot falls back to an older generation after a few attempts.
  boot.loader.systemd-boot.bootCounting.enable = true;

  # Best-effort auditing of the per-user manager. This is complain-only;
  # systemd-run can still select AppArmorProfile=unconfined.
  systemd.services."user@".serviceConfig.AppArmorProfile = "systemd-user";

  systemd.services.systemd-boot-check-no-failures = {
    description = "Check if Any System Units Failed";
    requiredBy = [ "boot-complete.target" ];
    after = [
      "default.target"
      "graphical.target"
      "multi-user.target"
    ];
    before = [ "boot-complete.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${config.systemd.package}/lib/systemd/systemd-boot-check-no-failures";
    };
  };

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
