{
  lib,
  myLib,
  config,
  inputs,
  pkgs,
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
    enable = myLib.mkEnabledOption "ClamAV";
    realtime = {
      enable = myLib.mkEnabledOption "ClamAV real-time scanning";
    };
  };
  config = {
    services.clamav = lib.mkIf myCfg.enable {
      scanner.enable = true;
      # /home is excluded: rclamonacc covers it in real-time, and scanning it
      # here deadlocks on rclamonacc's fanotify (scan blocked until clamd
      # responds, clamd busy serving the scan).
      scanner.scanDirectories = [
        "/var/lib"
        "/tmp"
        "/etc"
        "/var/tmp"
      ];
      updater.enable = true;
      daemon.enable = true;
    };

    # clamdscan exit codes: 0 = clean, 1 = infected files found,
    # 2 = an error occurred. Detection and per-file errors are expected
    # outcomes of a periodic scan; mark them successful so the timer does not
    # leave a permanently failed unit. Infected paths remain in the journal.
    systemd.services.clamdscan.serviceConfig.SuccessExitStatus = lib.mkIf myCfg.enable "1 2";

    # The unit is green for expected scan outcomes, but detection must not be
    # silent: leave a warning in the journal (journalctl -u clamdscan -p warning).
    systemd.services.clamdscan.serviceConfig.ExecStopPost = lib.mkIf myCfg.enable (
      pkgs.writeShellScript "clamdscan-result" ''
        case "''${EXIT_STATUS:-}" in
          1)
            ${pkgs.util-linux}/bin/logger -t clamdscan -p user.warning \
              "ClamAV detected infected files; see journalctl -u clamdscan"
            ;;
          2)
            ${pkgs.util-linux}/bin/logger -t clamdscan -p user.warning \
              "ClamAV scan finished with errors; see journalctl -u clamdscan"
            ;;
        esac
      ''
    );

    # realtime scanning only makes sense as part of ClamAV itself.
    services.rclamonacc = lib.mkIf (myCfg.enable && myCfg.realtime.enable) {
      enable = true;
      settings.directories = [ "/home" ];
    };

    # clamd's socket may not exist yet immediately after clamd starts; wait
    # instead of letting rclamonacc restart-loop into a failed unit.
    systemd.services.rclamonacc = lib.mkIf (myCfg.enable && myCfg.realtime.enable) {
      serviceConfig.ExecStartPre = pkgs.writeShellScript "wait-for-clamd-socket" ''
        for _ in {1..60}; do
          if [ -S ${lib.escapeShellArg config.services.rclamonacc.settings.socket_path} ] \
            && [ -s ${lib.escapeShellArg config.services.rclamonacc.settings.pid_path} ]; then
            exit 0
          fi
          sleep 1
        done
        echo "rclamonacc: clamd socket/PID file did not appear" >&2
        exit 1
      '';
    };

    # This only skips syncfs in switch-to-configuration; it does not affect
    # service startup. If you prefer not to set it system-wide, pass
    # NIXOS_NO_SYNC=1 to the nixos-rebuild invocation instead.
    # Avoid EIO: I/O errors during nixos-rebuild switch when rclamonacc is active.
    # When rclamonacc monitors directories, it marks their parent mountpoints (which may include /).
    # Under shared-filesystem setups (e.g. Btrfs subvolumes), syncfs("/nix/store") flushes all shared subvolumes,
    # triggering sync on monitored files, which can block on rclamonacc scan timeouts and return EIO.
    # Note: Bypassing syncfs sacrifices atomicity during switch. If a crash occurs mid-write, the new generation
    # may be corrupted, but you can recover by booting into a previous generation from the boot menu and rebuilding.
    environment.variables = lib.mkIf (myCfg.enable && myCfg.realtime.enable) {
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
