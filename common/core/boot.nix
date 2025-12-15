{ pkgs, ... }:

{
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    timeout = 0;
  };

  boot.kernel.sysctl."kernel.sysrq" = 1;

  boot.kernelPackages = pkgs.linuxPackages_zen;
}
