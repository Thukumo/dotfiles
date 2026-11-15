# Attic binary cache.
#
# SECURITY / NETWORK MODEL
#   - mycelium is treated as untrusted internet. Attic binds to 127.0.0.1 only.
#   - The only public path is nginx (127.0.0.1:8182) behind Cloudflare Tunnel.
#   - dotfiles: public read cache, used by hosts.
#   - Attic skips paths provided by cache.nixos.org and the configured Cachix
#     upstreams, so the narrow uplink and disk only carry what is missing.
#   - The signing key is generated outside Nix, stored with agenix, and imported
#     into Attic's database by atticd-bootstrap on first boot.
#   - The CI push token is rotated daily (7-day validity) and published as the
#     Forgejo Actions secret ATTIC_TOKEN.
#
# Future isolation:
#   This host runner / cache setup is intentionally not the final security
#   boundary. When moving CI into a microVM, keep Attic here and only change the
#   builder. 16x-aurora is not a planned CI builder.
{
  config,
  pkgs,
  ...
}:
let
  cache = import ../../../const/cache.nix;
  forgejoState = config.services.forgejo.stateDir;

  bootstrapScript = pkgs.writeShellScript "attic-cache-bootstrap" ''
    set -euo pipefail

    port=${toString cache.port}
    workdir="$(${pkgs.coreutils}/bin/mktemp -d)"
    trap '${pkgs.coreutils}/bin/rm -rf "$workdir"' EXIT
    keyfile="$workdir/key"
    auth_header="$workdir/auth"

    # Importing the Nix keypair must not leave a trailing newline in the JSON.
    ${pkgs.coreutils}/bin/tr -d '\r\n' < ${config.age.secrets.attic_signing_key.path} > "$keyfile"

    upstream='${builtins.toJSON cache.upstreamCacheKeyNames}'

    for _ in $(${pkgs.coreutils}/bin/seq 1 60); do
      if ${pkgs.curl}/bin/curl -sS -o /dev/null "http://127.0.0.1:$port/"; then
        break
      fi
      ${pkgs.coreutils}/bin/sleep 2
    done

    export PATH=/run/current-system/sw/bin:$PATH
    token="$(atticd-atticadm make-token \
      --sub bootstrap \
      --validity 1h \
      --create-cache 'dotfiles*' \
      --configure-cache 'dotfiles*' \
      --pull 'dotfiles*' \
      --push 'dotfiles*')"
    printf 'Authorization: Bearer %s\n' "$token" > "$auth_header"
    ${pkgs.coreutils}/bin/chmod 600 "$keyfile" "$auth_header"

    verify_cache() {
      name="$1"
      actual="$(${pkgs.curl}/bin/curl -fsS \
        -H "@$auth_header" \
        "http://127.0.0.1:$port/_api/v1/cache-config/$name" | \
        ${pkgs.jq}/bin/jq -r .public_key)"
      if [ "$actual" != "${cache.publicKey}" ]; then
        echo "cache $name has unexpected signing key: $actual" >&2
        exit 1
      fi
    }

    create_cache() {
      name="$1"
      public="$2"

      code="$(${pkgs.curl}/bin/curl -sS -o /dev/null -w '%{http_code}' \
        -H "@$auth_header" \
        "http://127.0.0.1:$port/_api/v1/cache-config/$name")"

      if [ "$code" = "200" ]; then
        verify_cache "$name"

        # Refresh the non-key settings on existing caches as well.
        ${pkgs.jq}/bin/jq -n \
          --argjson public "$public" \
          --argjson upstream "$upstream" \
          '{
            is_public: $public,
            priority: ${toString cache.priority},
            upstream_cache_key_names: $upstream
          }' | \
          ${pkgs.curl}/bin/curl -fsS \
            -X PATCH \
            -H "@$auth_header" \
            -H 'Content-Type: application/json' \
            --data-binary @- \
            "http://127.0.0.1:$port/_api/v1/cache-config/$name"
        return 0
      fi

      ${pkgs.jq}/bin/jq -n \
        --rawfile key "$keyfile" \
        --argjson public "$public" \
        --argjson upstream "$upstream" \
        '{
          keypair: { Keypair: $key },
          is_public: $public,
          store_dir: "/nix/store",
          priority: ${toString cache.priority},
          upstream_cache_key_names: $upstream
        }' | \
        ${pkgs.curl}/bin/curl -fsS \
          -H "@$auth_header" \
          -H 'Content-Type: application/json' \
          --data-binary @- \
          "http://127.0.0.1:$port/_api/v1/cache-config/$name"

      verify_cache "$name"
    }

    create_cache dotfiles true
  '';
in
{
  services.atticd = {
    enable = true;
    environmentFile = config.age.secrets.atticd_env.path;

    settings = {
      listen = "127.0.0.1:${toString cache.port}";
      allowed-hosts = [
        cache.domain
        "127.0.0.1:${toString cache.port}"
      ];
      api-endpoint = "https://${cache.domain}/";

      compression.type = "zstd";

      garbage-collection = {
        interval = "12 hours";
        default-retention-period = "14 days";
      };
    };
  };

  age.secrets = {
    atticd_env.file = ../secrets/atticd-env.age;
    attic_signing_key.file = ../secrets/attic-signing-key.age;
  };

  # Rotating atticd_env restarts the server and the token reconciler, so the
  # next switch remints and republishes a token signed by the new secret.
  systemd.services.atticd.restartTriggers = [ config.age.secrets.atticd_env.file ];
  systemd.services.attic-ci-tokens.restartTriggers = [ config.age.secrets.atticd_env.file ];

  # NOTE: /persist is snapshotted hourly by btrbk on this host, so cache
  # churn is retained by those snapshots. If space becomes tight, disable
  # snapshots here or move cache storage to a non-snapshotted subvolume.
  environment.persistence."/persist".directories = [
    "/var/lib/private/atticd"
  ];

  systemd.services.atticd-bootstrap = {
    description = "Create Attic caches and import the signing key";
    wantedBy = [ "multi-user.target" ];
    after = [ "atticd.service" ];
    # Wants, not Requires: a transient Attic failure must not prevent this
    # oneshot from starting and retrying.
    wants = [ "atticd.service" ];
    startLimitIntervalSec = 0;

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = 30;
      TimeoutStartSec = "10min";
      ExecStart = bootstrapScript;
    };
  };

  # Rotate the Attic push token daily and publish it as the Forgejo Actions
  # secret ATTIC_TOKEN. The token file is root-only; CI jobs only see the
  # Forgejo secret. A 7-day validity limits the impact of a leak.
  # Change tsukumo/dotfiles below if the Forgejo owner/repository differs.
  systemd.services.attic-ci-tokens = {
    description = "Publish the Attic CI push token as a Forgejo Actions secret";
    wantedBy = [ "multi-user.target" ];
    after = [
      "atticd.service"
      "atticd-bootstrap.service"
      "forgejo-bootstrap.service"
      "forgejo-import.service"
    ];
    wants = [
      "atticd.service"
      "atticd-bootstrap.service"
      "forgejo-bootstrap.service"
      "forgejo-import.service"
    ];
    startLimitIntervalSec = 0;

    serviceConfig = {
      Type = "oneshot";
      Restart = "on-failure";
      RestartSec = 60;
      TimeoutStartSec = "5min";
    };

    script = ''
      set -euo pipefail

      token_file=/var/lib/attic-ci-token
      port=${toString cache.port}
      admin_token="$(${pkgs.coreutils}/bin/tr -d '\r\n' < ${forgejoState}/bootstrap-token)"
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
      if [ "$repo_code" = "401" ] || [ "$repo_code" = "403" ]; then
        echo "Forgejo bootstrap token is invalid; delete the bootstrap token in the UI, remove /var/lib/forgejo/bootstrap-token, and restart forgejo-bootstrap" >&2
        exit 1
      fi
      if [ "$repo_code" != "200" ]; then
        echo "Forgejo repository is not ready: $repo_code" >&2
        exit 1
      fi

      export PATH=/run/current-system/sw/bin:$PATH
      token="$(atticd-atticadm make-token \
        --sub ci --validity '7 days' --pull dotfiles --push dotfiles)"

      umask 077
      tmp="$workdir/token"
      printf '%s' "$token" > "$tmp"
      ${pkgs.coreutils}/bin/install -m 0600 -o root -g root "$tmp" "$token_file"

      attic_header="$workdir/attic"
      printf 'Authorization: Bearer %s\n' "$(${pkgs.coreutils}/bin/cat "$token_file")" > "$attic_header"
      ${pkgs.coreutils}/bin/chmod 600 "$attic_header"
      cache_code="$(${pkgs.curl}/bin/curl -sS -o /dev/null -w '%{http_code}' \
        -H "@$attic_header" \
        "http://127.0.0.1:$port/dotfiles/nix-cache-info")"
      if [ "$cache_code" != "200" ]; then
        echo "Attic cache dotfiles is not available: $cache_code" >&2
        exit 1
      fi

      ${pkgs.jq}/bin/jq -n --rawfile data "$token_file" '{ data: $data }' | \
        ${pkgs.curl}/bin/curl -fsS \
          -X PUT \
          -H "@$auth_header" \
          -H 'Content-Type: application/json' \
          --data-binary @- \
          http://127.0.0.1:3000/api/v1/repos/tsukumo/dotfiles/actions/secrets/ATTIC_TOKEN >/dev/null
    '';
  };

  systemd.timers.attic-ci-tokens = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "15m";
    };
  };
}
