{
  lib,
  myLib,
  config,
  inputs,
  ...
}:
let
  myCfg = config.custom.security.clamav;
in
{
  imports = [
    inputs.nur.nixosModules.rclamonacc
  ];

  options.custom.security.clamav = {
    enable = myLib.mkEnabledOption;
    realtime = {
      enable = myLib.mkEnabledOption;
    };
  };
  config = {
    services.clamav = lib.mkIf myCfg.enable {
      scanner.enable = true;
      updater.enable = true;
      daemon.enable = true;
    };

    services.rclamonacc = lib.mkIf myCfg.realtime.enable {
      enable = true;
      settings.directories = [ "/home" ];
    };

    # Avoid EIO: I/O errors during nixos-rebuild switch when rclamonacc is active.
    # When rclamonacc monitors directories, it marks their parent mountpoints (which may include /).
    # Under shared-filesystem setups (e.g. Btrfs subvolumes), syncfs("/nix/store") flushes all shared subvolumes,
    # triggering sync on monitored files, which can block on rclamonacc scan timeouts and return EIO.
    # Note: Bypassing syncfs sacrifices atomicity during switch. If a crash occurs mid-write, the new generation
    # may be corrupted, but you can recover by booting into a previous generation from the boot menu and rebuilding.
    environment.variables = lib.mkIf myCfg.realtime.enable {
      NIXOS_NO_SYNC = "1";
    };

    environment.persistence."/persist".directories = lib.mkIf myCfg.enable [
      {
        directory = "/var/lib/clamav";
        user = "clamav";
        group = "clamav";
        mode = "755";
      }
    ];
  };
}
