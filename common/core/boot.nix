{
  pkgs,
  lib,
  config,
  ...
}:

{
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    timeout = 0;
  };

  boot.kernelParams = [
    "quiet"
    "rd.udev.log_level=${toString config.boot.consoleLogLevel}"

    "rd.systemd.show_status=false"
    "systemd.show_status=false"
  ];
  boot.consoleLogLevel = lib.mkDefault 4;

  boot.kernel.sysctl."kernel.sysrq" = 242;

  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_zen;

  # Automatic Boot Assessment: enable only the setting the host's bootloader uses.
  boot.loader.systemd-boot.bootCounting.enable = !config.boot.lanzaboote.enable;
  # Lanzaboote has no separate enable flag; 0 disables boot counting.
  boot.lanzaboote.bootCounting.initialTries = lib.mkIf config.boot.lanzaboote.enable 3;

  # A boot with failed units is not marked good, so the bootloader falls back
  # to an older generation after a few attempts.
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
}
