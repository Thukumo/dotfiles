# Forgejo Actions runner for this repository.
#
# SECURITY: this is a host-mode runner. It is NOT isolated from mouse-3:
#   - workflow steps run as the runner's ephemeral user on this host
#   - it can read /nix/store, use the Nix daemon to add/build paths, and use
#     the network
#   - it is not root, and it cannot modify existing store paths
#
# Therefore only trusted refs are built in practice:
#   - pushes to master
# Other pull requests only run evaluation/pre-commit checks. Renovate uses the
# Forgejo automatic token, and Forgejo suppresses workflow events from that
# token, so Renovate PRs do not trigger CI.
#
# Future isolation:
#   Move the runner into a microVM on this host, keep Attic here, and stop
#   using the host store for CI. 16x-aurora is not a planned CI builder.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  runnerToken = config.age.secrets.forgejo_runner_token.path;
  forgejoState = config.services.forgejo.stateDir;
  forgejoExe = lib.getExe config.services.forgejo.package;

  # The UUID is derived from the first 16 characters of the runner secret,
  # interpreted as bytes (not hex digits). Keep this in sync with
  # hosts/mouse-3/secrets/forgejo-runner-token.age.
  runnerUuid = "38363333-3863-6133-6565-313939363263";
in
{
  # Host-wide build limits: CI and manual rebuilds both run on this 2C/4T,
  # 7.6GiB host. The Nix client cannot scope these to one service.
  nix.settings = {
    max-jobs = 1;
    cores = 2;
  };

  age.secrets.forgejo_runner_token.file = ../secrets/forgejo-runner-token.age;

  services.forgejo-runner.instances.ci = {
    enable = true;

    settings = {
      server.connections.default = {
        url = "http://127.0.0.1:3000/";
        uuid = runnerUuid;
      };

      runner = {
        labels = [ "nix:host" ];
        capacity = 1;
        timeout = "12h";
      };

      log.level = "info";
    };

    secrets.server.connections.default.token_url = runnerToken;

    hostPackages = with pkgs; [
      config.nix.package
      git
      jq
      curl
      nodejs
      bash
      coreutils
      gnused
      gawk
      attic-client
      renovate
      openssh
      cacert
    ];
  };

  # The Forgejo runner service uses an age secret. Do not let it start before
  # the secret has been decrypted.
  systemd.services.forgejo-runner-ci = {
    after = [
      "forgejo.service"
      "forgejo-bootstrap.service"
      "forgejo-runner-register.service"
      "attic-ci-tokens.service"
    ];
    wants = [
      "forgejo-bootstrap.service"
      "forgejo-runner-register.service"
      "attic-ci-tokens.service"
    ];

    # Defense in depth, not a replacement for a VM. Nix builds still use the
    # host Nix daemon and are sandboxed there.
    serviceConfig = {
      ProtectSystem = "full";
      ProtectHome = "tmpfs";
      ProtectProc = "invisible";
      PrivateTmp = true;
      NoNewPrivileges = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      ProtectClock = true;
      ProtectHostname = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      LockPersonality = true;
      SystemCallArchitectures = "native";
      RestrictAddressFamilies = [
        "AF_UNIX"
        "AF_INET"
        "AF_INET6"
        "AF_NETLINK"
      ];
      MemoryMax = "4G";
      CPUQuota = "200%";
      TasksMax = 4096;
    };
  };

  # Offline runner registration. The admin user is created by
  # forgejo-bootstrap. Change the --scope below if the owner is not tsukumo.
  systemd.services.forgejo-runner-register = {
    description = "Register the mouse-3 Forgejo Actions runner";
    wantedBy = [ "multi-user.target" ];
    after = [
      "forgejo.service"
      "forgejo-bootstrap.service"
    ];
    wants = [
      "forgejo.service"
      "forgejo-bootstrap.service"
    ];
    startLimitIntervalSec = 0;

    path = with pkgs; [
      coreutils
      util-linux
      bash
      curl
      git
    ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = 60;
      TimeoutStartSec = "10min";
    };

    script = ''
      set -euo pipefail

      token_file=${runnerToken}
      if [ ! -s "$token_file" ]; then
        echo "forgejo runner token secret is missing" >&2
        exit 1
      fi

      # The Forgejo service may still be starting.
      for _ in $(seq 1 120); do
        if ${pkgs.curl}/bin/curl -fsS http://127.0.0.1:3000/api/v1/version >/dev/null 2>&1; then
          break
        fi
        sleep 2
      done

      # --secret-stdin is a string flag; the dummy value satisfies the parser.
      # The actual secret is read from stdin and trimmed to exactly 40 chars.
      token="$(${pkgs.coreutils}/bin/tr -d '\r\n' < "$token_file")"
      expected_uuid="$(printf '%s' "''${token:0:16}" |
        ${pkgs.coreutils}/bin/od -An -tx1 -v |
        ${pkgs.coreutils}/bin/tr -d ' \n' |
        ${pkgs.gnused}/bin/sed 's/\(........\)\(....\)\(....\)\(....\)\(............\)/\1-\2-\3-\4-\5/')"
      if [ "$expected_uuid" != "${runnerUuid}" ]; then
        echo "runner token does not match runnerUuid: expected ${runnerUuid}, got $expected_uuid" >&2
        exit 1
      fi

      printf '%s' "$token" |
        ${pkgs.util-linux}/bin/runuser -u forgejo -- \
          ${pkgs.coreutils}/bin/env HOME=${forgejoState} \
          ${forgejoExe} \
          --work-path ${forgejoState} \
          --config ${forgejoState}/custom/conf/app.ini \
          forgejo-cli actions register \
          --name mouse-3 \
          --scope tsukumo \
          --labels nix \
          --secret-stdin unused
    '';
  };
}
