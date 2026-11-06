# Secrets Access Matrix
Generated on 2026-11-07 06:35:19

> **GENERATED FILE** - do not edit manually.
> Regenerate with `pre-commit run gen-docs --all-files`.

## Legend

- Decrypted secrets are mode `0400`.
- System secrets are exposed at the runtime path shown.
- Home secrets are exposed at the runtime path shown; `Home path` is the optional symlink relative to the user's home (`—` means no symlink).
- Dedicated service daemons get an AppArmor profile limited to their secrets. Programs marked `accepted risk` are interactive and are not profiled; their secrets are intentionally user-readable.
- Complain mode still enforces explicit deny rules; a reader not listed under `Programs` or `Consumers` is denied the protected path.
- The fallback denies consumer-delivered home secrets and identity keys. systemd --user (on every host) is allowed consumer-delivered secrets; the home-manager agenix service gets a trusted profile for the home identity key. `age`/`ragenix` may read the root-only system identity key during activation but deny the home identity key.
- Service profiles attach to `/nix/store/*/bin/<name>`; executables outside `bin` are not matched. Profiles are per executable basename, so same-named binaries from different packages share a profile.
- Helper binaries (jq, ssh-add, git, ...) are not profiled. Interactive secrets marked `accepted risk` are readable by the user's processes, including helpers.

## 16x-aurora

### System secrets

| Secret | Kind | File | Runtime | Owner:Group | Consumers | Programs | Trust |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `eduroam` | `owner` | `common/network/wifi/eduroam.age` | `/run/agenix/eduroam` | `wpa_supplicant:wpa_supplicant` | — | `wpa_supplicant` | trusted |
| `passwd_tsukumo` | `root` | `common/core/users/passwd_tsukumo.age` | `/run/agenix/passwd_tsukumo` | `root:root` | — | — | trusted |
| `wifi-pwds` | `owner` | `common/network/wifi/pwds.age` | `/run/agenix/wifi-pwds` | `wpa_supplicant:wpa_supplicant` | — | `wpa_supplicant` | trusted |

### Home secrets (`tsukumo`)

| Secret | File | Runtime | Home path | Consumers | Programs | Trust |
| --- | --- | --- | --- | --- | --- | --- |
| `github_credential` | `common/shell/git/gh_hosts_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/github_credential` | `.config/gh/hosts.yml` | — | `gh` | accepted risk: `interactive user program; AppArmor profile skipped` |
| `nix_access_tokens` | `common/shell/private/nix-access-tokens.age` | `${XDG_RUNTIME_DIR}/agenix/nix_access_tokens` | `.config/nix/access-tokens` | — | `nix` | accepted risk: `interactive user program; AppArmor profile skipped` |
| `nowplaying_token` | `common/desktop/services/nowplaying/nowplaying-token.age` | `${XDG_RUNTIME_DIR}/agenix/nowplaying_token` | — | `nowplaying-bridge` | — | trusted |
| `opencode_auth` | `common/dev/opencode/auth_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/opencode_auth` | `.local/share/opencode/auth.json` | — | `opencode` | accepted risk: `interactive user program; AppArmor profile skipped` |
| `ssh_key` | `common/shell/ssh/ssh-key_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/ssh_key` | `.ssh/id_ed25519` | — | `ssh`, `ssh-keygen` | accepted risk: `interactive user program; AppArmor profile skipped` |

## mouse-3

### System secrets

| Secret | Kind | File | Runtime | Owner:Group | Consumers | Programs | Trust |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `cloudflared_nowplaying` | `credential` | `hosts/mouse-3/secrets/cloudflared-nowplaying-credentials.age` | `/run/agenix/cloudflared_nowplaying` | `root:root` | `cloudflared-tunnel-mouse-3` | `cloudflared` | trusted |
| `passwd_tsukumo` | `root` | `common/core/users/passwd_tsukumo.age` | `/run/agenix/passwd_tsukumo` | `root:root` | — | — | trusted |

### Home secrets (`tsukumo`)

| Secret | File | Runtime | Home path | Consumers | Programs | Trust |
| --- | --- | --- | --- | --- | --- | --- |
| `github_credential` | `common/shell/git/gh_hosts_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/github_credential` | `.config/gh/hosts.yml` | — | `gh` | accepted risk: `interactive user program; AppArmor profile skipped` |
| `nix_access_tokens` | `common/shell/private/nix-access-tokens.age` | `${XDG_RUNTIME_DIR}/agenix/nix_access_tokens` | `.config/nix/access-tokens` | — | `nix` | accepted risk: `interactive user program; AppArmor profile skipped` |
| `nowplaying_token` | `common/desktop/services/nowplaying/nowplaying-token.age` | `${XDG_RUNTIME_DIR}/agenix/nowplaying_token` | — | `podman-nowplaying` | — | trusted |
| `opencode_auth` | `common/dev/opencode/auth_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/opencode_auth` | `.local/share/opencode/auth.json` | — | `opencode` | accepted risk: `interactive user program; AppArmor profile skipped` |
| `opencode_web_password` | `common/dev/opencode/opencode-web-password.age` | `${XDG_RUNTIME_DIR}/agenix/opencode_web_password` | — | `opencode-web` | — | trusted |
| `ssh_key` | `common/shell/ssh/ssh-key_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/ssh_key` | `.ssh/id_ed25519` | — | `ssh`, `ssh-keygen` | accepted risk: `interactive user program; AppArmor profile skipped` |

## thinkpadx13-nix

### System secrets

| Secret | Kind | File | Runtime | Owner:Group | Consumers | Programs | Trust |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `eduroam` | `owner` | `common/network/wifi/eduroam.age` | `/run/agenix/eduroam` | `wpa_supplicant:wpa_supplicant` | — | `wpa_supplicant` | trusted |
| `passwd_tsukumo` | `root` | `common/core/users/passwd_tsukumo.age` | `/run/agenix/passwd_tsukumo` | `root:root` | — | — | trusted |
| `wifi-pwds` | `owner` | `common/network/wifi/pwds.age` | `/run/agenix/wifi-pwds` | `wpa_supplicant:wpa_supplicant` | — | `wpa_supplicant` | trusted |

### Home secrets (`tsukumo`)

| Secret | File | Runtime | Home path | Consumers | Programs | Trust |
| --- | --- | --- | --- | --- | --- | --- |
| `github_credential` | `common/shell/git/gh_hosts_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/github_credential` | `.config/gh/hosts.yml` | — | `gh` | accepted risk: `interactive user program; AppArmor profile skipped` |
| `nix_access_tokens` | `common/shell/private/nix-access-tokens.age` | `${XDG_RUNTIME_DIR}/agenix/nix_access_tokens` | `.config/nix/access-tokens` | — | `nix` | accepted risk: `interactive user program; AppArmor profile skipped` |
| `nowplaying_token` | `common/desktop/services/nowplaying/nowplaying-token.age` | `${XDG_RUNTIME_DIR}/agenix/nowplaying_token` | — | `nowplaying-bridge` | — | trusted |
| `opencode_auth` | `common/dev/opencode/auth_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/opencode_auth` | `.local/share/opencode/auth.json` | — | `opencode` | accepted risk: `interactive user program; AppArmor profile skipped` |
| `ssh_key` | `common/shell/ssh/ssh-key_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/ssh_key` | `.ssh/id_ed25519` | — | `ssh`, `ssh-keygen` | accepted risk: `interactive user program; AppArmor profile skipped` |

## yoga-book

### System secrets

| Secret | Kind | File | Runtime | Owner:Group | Consumers | Programs | Trust |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `eduroam` | `owner` | `common/network/wifi/eduroam.age` | `/run/agenix/eduroam` | `wpa_supplicant:wpa_supplicant` | — | `wpa_supplicant` | trusted |
| `passwd_tsukumo` | `root` | `common/core/users/passwd_tsukumo.age` | `/run/agenix/passwd_tsukumo` | `root:root` | — | — | trusted |
| `wifi-pwds` | `owner` | `common/network/wifi/pwds.age` | `/run/agenix/wifi-pwds` | `wpa_supplicant:wpa_supplicant` | — | `wpa_supplicant` | trusted |

### Home secrets (`tsukumo`)

| Secret | File | Runtime | Home path | Consumers | Programs | Trust |
| --- | --- | --- | --- | --- | --- | --- |
| `github_credential` | `common/shell/git/gh_hosts_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/github_credential` | `.config/gh/hosts.yml` | — | `gh` | accepted risk: `interactive user program; AppArmor profile skipped` |
| `nix_access_tokens` | `common/shell/private/nix-access-tokens.age` | `${XDG_RUNTIME_DIR}/agenix/nix_access_tokens` | `.config/nix/access-tokens` | — | `nix` | accepted risk: `interactive user program; AppArmor profile skipped` |
| `nowplaying_token` | `common/desktop/services/nowplaying/nowplaying-token.age` | `${XDG_RUNTIME_DIR}/agenix/nowplaying_token` | — | `nowplaying-bridge` | — | trusted |
| `opencode_auth` | `common/dev/opencode/auth_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/opencode_auth` | `.local/share/opencode/auth.json` | — | `opencode` | accepted risk: `interactive user program; AppArmor profile skipped` |
| `ssh_key` | `common/shell/ssh/ssh-key_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/ssh_key` | `.ssh/id_ed25519` | — | `ssh`, `ssh-keygen` | accepted risk: `interactive user program; AppArmor profile skipped` |
