{ pkgs, lib, ... }:

{
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    timeout = 0;
  };

  boot.kernelParams = [
    "loglevel=4"
    "rd.udev.log_level=3"
    "rd.systemd.show_status=auto"
  ];
  boot.consoleLogLevel = 4;

  boot.initrd.systemd.enable = true;

  boot.kernel.sysctl."kernel.sysrq" = 242;

  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_zen;
}
