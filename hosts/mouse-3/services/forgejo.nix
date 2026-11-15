# Forgejo is the primary Git server for this repository.
#
# Network exposure:
#   - Forgejo itself listens on 127.0.0.1:3000 only.
#   - The public entrypoint is nginx (127.0.0.1:8182) behind the existing
#     Cloudflare Tunnel; mycelium is treated as untrusted internet.
#   - Built-in SSH is disabled. Git uses HTTPS only.
#
# Authentication / repository policy:
#   - The dotfiles repository is public read; anonymous hosts can pull it.
#   - Registration and forking are disabled; only trusted users can write.
#   - The admin user is created from the agenix-managed password on first boot.
#     Enable TOTP or a security key in the UI after the first login.
#   - Cloudflare Tunnel provides transport encryption only; it is not an
#     authentication layer.
#   - On first boot the public GitHub history is imported automatically.
#     Push-to-create remains enabled as a manual fallback.
#   - The local import and secret reconcilers use a root-only admin access
#     token. Forgejo rejects duplicate token names, so rotation requires
#     deleting the "bootstrap" token in the UI/API before removing the file.
#   - The GitHub push mirror is configured from the agenix-managed
#     github_push_mirror_token (a fine-grained PAT).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  stateDir = config.services.forgejo.stateDir;
  forgejoExe = lib.getExe config.services.forgejo.package;
  adminPassword = config.age.secrets.forgejo_admin_password.path;
  githubPushMirrorToken = config.age.secrets.github_push_mirror_token.path;
  bootstrapToken = "${stateDir}/bootstrap-token";

  importScript = pkgs.writeShellScript "forgejo-import" ''
    set -euo pipefail

    marker=${stateDir}/.github-import-complete

    admin_token="$(${pkgs.coreutils}/bin/tr -d '\r\n' < ${bootstrapToken})"
    if [ -z "$admin_token" ]; then
      echo "Forgejo bootstrap token is empty" >&2
      exit 1
    fi

    workdir="$(${pkgs.coreutils}/bin/mktemp -d)"
    trap '${pkgs.coreutils}/bin/rm -rf "$workdir"' EXIT
    auth_header="$workdir/auth"
    printf 'Authorization: token %s\n' "$admin_token" > "$auth_header"
    ${pkgs.coreutils}/bin/chmod 600 "$auth_header"

    repo_code="$(${pkgs.curl}/bin/curl -sS -o /dev/null -w '%{http_code}' \
      -H "@$auth_header" \
      http://127.0.0.1:3000/api/v1/repos/tsukumo/dotfiles)"
    case "$repo_code" in
      404)
        ${pkgs.coreutils}/bin/rm -f "$marker"
        ;;
      200)
        if [ -e "$marker" ]; then
          branch_code="$(${pkgs.curl}/bin/curl -sS -o /dev/null -w '%{http_code}' \
            -H "@$auth_header" \
            http://127.0.0.1:3000/api/v1/repos/tsukumo/dotfiles/branches/master)"
          case "$branch_code" in
            200) exit 0 ;;
            404) ${pkgs.coreutils}/bin/rm -f "$marker" ;;
            *)
              echo "unexpected Forgejo branch status: $branch_code" >&2
              exit 1
              ;;
          esac
        fi
        ;;
      401 | 403)
        echo "Forgejo bootstrap token is invalid; delete the bootstrap token in the UI, remove /var/lib/forgejo/bootstrap-token, and restart forgejo-bootstrap" >&2
        exit 1
        ;;
      *)
        echo "unexpected Forgejo repository status: $repo_code" >&2
        exit 1
        ;;
    esac

    export GIT_SSL_CAINFO=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
    export GIT_TERMINAL_PROMPT=0
    ${pkgs.git}/bin/git clone --bare https://github.com/thukumo/dotfiles.git "$workdir/repo.git"

    # If the marker was lost but the repo is already populated, only accept it
    # when master matches GitHub. Do not overwrite local/diverged history.
    if [ "$repo_code" = "200" ] && [ ! -e "$marker" ]; then
      branch_code="$(${pkgs.curl}/bin/curl -sS -o /dev/null -w '%{http_code}' \
        -H "@$auth_header" \
        http://127.0.0.1:3000/api/v1/repos/tsukumo/dotfiles/branches/master)"
      if [ "$branch_code" = "200" ]; then
        github_master="$(${pkgs.git}/bin/git -C "$workdir/repo.git" rev-parse refs/heads/master)"
        forgejo_master="$(${pkgs.curl}/bin/curl -fsS \
          -H "@$auth_header" \
          http://127.0.0.1:3000/api/v1/repos/tsukumo/dotfiles/branches/master | \
          ${pkgs.jq}/bin/jq -r .commit.id)"
        if [ "$github_master" = "$forgejo_master" ]; then
          ${pkgs.coreutils}/bin/touch "$marker"
          exit 0
        fi
        echo "Forgejo master differs from GitHub; refusing to overwrite. Delete the Forgejo repository or reconcile manually." >&2
        exit 1
      elif [ "$branch_code" != "404" ]; then
        echo "unexpected Forgejo branch status: $branch_code" >&2
        exit 1
      fi
    fi

    # The token goes through the environment, not argv. The push is also safe
    # to retry when the marker was lost but the refs are unchanged.
    git_push() {
      GIT_CONFIG_COUNT=1 \
      GIT_CONFIG_KEY_0=http.extraHeader \
      GIT_CONFIG_VALUE_0="Authorization: token $admin_token" \
        ${pkgs.git}/bin/git -C "$workdir/repo.git" "$@"
    }
    git_push push --all http://127.0.0.1:3000/tsukumo/dotfiles.git
    git_push push --tags http://127.0.0.1:3000/tsukumo/dotfiles.git

    ${pkgs.coreutils}/bin/touch "$marker"
  '';

  pushMirrorScript = pkgs.writeShellScript "forgejo-push-mirror" ''
    set -euo pipefail

    remote="https://github.com/thukumo/dotfiles.git"
    token="$(${pkgs.coreutils}/bin/tr -d '\r\n' < ${githubPushMirrorToken})"

    # The age file is created with REPLACE_ME so the default deployment is
    # harmless. Encrypt the real fine-grained PAT into that file and restart
    # forgejo-push-mirror (or wait for the next timer run).
    if [ -z "$token" ] || [ "$token" = "REPLACE_ME" ]; then
      echo "github push mirror token is not configured" >&2
      exit 0
    fi

    admin_token="$(${pkgs.coreutils}/bin/tr -d '\r\n' < ${bootstrapToken})"
    if [ -z "$admin_token" ]; then
      echo "Forgejo bootstrap token is empty" >&2
      exit 1
    fi

    workdir="$(${pkgs.coreutils}/bin/mktemp -d)"
    trap '${pkgs.coreutils}/bin/rm -rf "$workdir"' EXIT
    auth_header="$workdir/auth"
    pass_file="$workdir/pass"
    printf 'Authorization: token %s\n' "$admin_token" > "$auth_header"
    ${pkgs.coreutils}/bin/tr -d '\r\n' < ${githubPushMirrorToken} > "$pass_file"
    ${pkgs.coreutils}/bin/chmod 600 "$auth_header" "$pass_file"

    repo_code="$(${pkgs.curl}/bin/curl -sS -o /dev/null -w '%{http_code}' \
      -H "@$auth_header" \
      http://127.0.0.1:3000/api/v1/repos/tsukumo/dotfiles)"
    if [ "$repo_code" = "401" ] || [ "$repo_code" = "403" ]; then
      echo "Forgejo bootstrap token is invalid; delete the bootstrap token in the UI, remove /var/lib/forgejo/bootstrap-token, and restart forgejo-bootstrap" >&2
      exit 1
    fi
    if [ "$repo_code" != "200" ]; then
      echo "Forgejo repository is not ready: $repo_code" >&2
      exit 1
    fi

    mirrors="$(${pkgs.curl}/bin/curl -fsS \
      -H "@$auth_header" \
      http://127.0.0.1:3000/api/v1/repos/tsukumo/dotfiles/push_mirrors)"

    mirror_error="$(printf '%s' "$mirrors" | ${pkgs.jq}/bin/jq -r --arg remote "$remote" \
      '.[] | select(.remote_address == $remote) | .last_error // ""')"
    if [ -n "$mirror_error" ]; then
      echo "push mirror has an error: $mirror_error" >&2
      exit 1
    fi

    if printf '%s' "$mirrors" | ${pkgs.jq}/bin/jq -e --arg remote "$remote" \
      'any(.[]; .remote_address == $remote)' >/dev/null; then
      exit 0
    fi

    ${pkgs.jq}/bin/jq -n \
      --arg remote "$remote" \
      --arg user "thukumo" \
      --rawfile pass "$pass_file" \
      '{
        remote_address: $remote,
        remote_username: $user,
        remote_password: $pass,
        sync_on_commit: true,
        interval: "8h"
      }' | \
      ${pkgs.curl}/bin/curl -fsS \
        -X POST \
        -H "@$auth_header" \
        -H 'Content-Type: application/json' \
        --data-binary @- \
        http://127.0.0.1:3000/api/v1/repos/tsukumo/dotfiles/push_mirrors >/dev/null
  '';

  bootstrapScript = pkgs.writeShellScript "forgejo-bootstrap" ''
    set -euo pipefail

    for _ in $(${pkgs.coreutils}/bin/seq 1 120); do
      if ${pkgs.curl}/bin/curl -fsS http://127.0.0.1:3000/api/v1/version >/dev/null 2>&1; then
        break
      fi
      ${pkgs.coreutils}/bin/sleep 2
    done

    password="$(${pkgs.coreutils}/bin/tr -d '\r\n' < ${adminPassword})"

    run_forgejo() {
      ${pkgs.util-linux}/bin/runuser -u forgejo -- \
        ${pkgs.coreutils}/bin/env HOME=${stateDir} \
        ${forgejoExe} --work-path ${stateDir} --config ${stateDir}/custom/conf/app.ini "$@"
    }

    if ! run_forgejo admin user list 2>/dev/null | \
      ${pkgs.gawk}/bin/awk '$2 == "tsukumo" { found = 1 } END { exit !found }'; then
      run_forgejo admin user create \
        --admin \
        --username tsukumo \
        --email contact@tsukumo.f5.si \
        --password "$password" \
        --must-change-password=false
    fi

    # Used by forgejo-import and attic-ci-tokens.
    # Rotation: delete the "bootstrap" token in the Forgejo UI/API first, then
    # delete this file and restart forgejo-bootstrap. Forgejo rejects duplicate
    # token names, so deleting only this file is not enough.
    if [ ! -s ${bootstrapToken} ]; then
      tmp="$(${pkgs.coreutils}/bin/mktemp)"
      trap '${pkgs.coreutils}/bin/rm -f "$tmp"' EXIT

      run_forgejo admin user generate-access-token \
        --username tsukumo \
        --token-name bootstrap \
        --scopes write:repository \
        --raw > "$tmp"

      ${pkgs.coreutils}/bin/install -m 0600 -o root -g root "$tmp" ${bootstrapToken}
    fi
  '';
in
{
  services.forgejo = {
    enable = true;
    database.type = "sqlite3";
    stateDir = "/var/lib/forgejo";
    lfs.enable = true;

    settings = {
      DEFAULT.APP_NAME = "tsukumo git";

      server = {
        DOMAIN = "git.tsukumo.f5.si";
        ROOT_URL = "https://git.tsukumo.f5.si/";
        HTTP_ADDR = "127.0.0.1";
        HTTP_PORT = 3000;
        DISABLE_SSH = true;
      };

      service = {
        DISABLE_REGISTRATION = true;
        REQUIRE_SIGNIN_VIEW = false;
      };

      repository = {
        DEFAULT_BRANCH = "master";
        ENABLE_PUSH_CREATE_USER = true;
        DEFAULT_PUSH_CREATE_PRIVATE = false;
        # The host runner is not isolated; keep external fork PRs out.
        DISABLE_FORKS = true;
      };

      actions.ENABLED = true;
      session.COOKIE_SECURE = true;
      security.INSTALL_LOCK = true;
      log.LEVEL = "Info";
    };
  };

  age.secrets = {
    forgejo_admin_password.file = ../secrets/forgejo-admin-password.age;
    github_push_mirror_token.file = ../secrets/github-push-mirror-token.age;
  };

  environment.persistence."/persist".directories = [
    "/var/lib/forgejo"
  ];

  systemd.services.forgejo-bootstrap = {
    description = "Create the Forgejo admin user and bootstrap token";
    wantedBy = [ "multi-user.target" ];
    after = [ "forgejo.service" ];
    wants = [ "forgejo.service" ];
    startLimitIntervalSec = 600;
    startLimitBurst = 5;

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = 60;
      TimeoutStartSec = "10min";
      ExecStart = bootstrapScript;
    };
  };

  # Recover from a transient bootstrap failure after the start limit is hit.
  systemd.timers.forgejo-bootstrap = {
    wantedBy = [ "timers.target" ];
    timerConfig.OnUnitInactiveSec = "15min";
  };

  systemd.services.forgejo-import = {
    description = "Import the public GitHub history into Forgejo";
    wantedBy = [ "multi-user.target" ];
    after = [
      "forgejo.service"
      "forgejo-bootstrap.service"
      "network-online.target"
    ];
    wants = [
      "forgejo-bootstrap.service"
      "network-online.target"
    ];
    startLimitIntervalSec = 600;
    startLimitBurst = 5;

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = 60;
      TimeoutStartSec = "30min";
      ExecStart = importScript;
    };
  };

  # Retry a failed import without a 60-second re-clone loop.
  systemd.timers.forgejo-import = {
    wantedBy = [ "timers.target" ];
    timerConfig.OnCalendar = "*:0/15";
  };

  # Declarative Forgejo push mirror. The fine-grained GitHub PAT is the only
  # external input; keep it in the agenix file. Existing mirrors are left
  # alone; to rotate the PAT, delete the mirror in Forgejo and restart this.
  # Forgejo mirrors force-push all refs, so treat GitHub as read-only: direct
  # GitHub commits/branches can be pruned on the next sync.
  systemd.services.forgejo-push-mirror = {
    description = "Configure the Forgejo push mirror to GitHub";
    wantedBy = [ "multi-user.target" ];
    after = [
      "forgejo.service"
      "forgejo-import.service"
    ];
    requires = [ "forgejo-import.service" ];
    startLimitIntervalSec = 600;
    startLimitBurst = 5;

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = 60;
      TimeoutStartSec = "5min";
      ExecStart = pushMirrorScript;
    };
  };

  systemd.timers.forgejo-push-mirror = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*:0/15";
      RandomizedDelaySec = "1m";
    };
  };
}
