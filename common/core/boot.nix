{ pkgs, lib, ... }:

{
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    timeout = 0;
  };

  boot.kernel.sysctl."kernel.sysrq" = 242;

  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_zen;
}
