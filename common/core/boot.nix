{ pkgs, lib, ... }:

{
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    timeout = 0;
  };

  boot.kernelParams = [
    "quiet"
    "loglevel=3"
    "rd.udev.log_level=3"
    "rd.systemd.show_status=false"
  ];
  boot.consoleLogLevel = 0;

  # boot.initrd.systemd.enable = true;

  boot.kernel.sysctl."kernel.sysrq" = 242;

  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_zen;
}
