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

  boot.initrd.systemd.enable = true;

  boot.kernel.sysctl."kernel.sysrq" = 242;

  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_zen;
}
