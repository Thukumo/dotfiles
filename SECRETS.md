# Secrets Inventory
Generated on 2026-11-07 23:57:32

> **GENERATED FILE** - do not edit manually.
> Regenerate with `pre-commit run gen-docs --all-files`.

## Legend

- System secrets are protected by DAC and `LoadCredential`; no AppArmor profiles are used.
- Home secrets are decrypted to user-owned runtime paths and are user-level; AppArmor is not used. `Home path` is an optional symlink (`—` means no symlink).
- `Runtime` is the path consumed by services.

## 16x-aurora

### System secrets

| Secret | File | Runtime | Owner:Group | Mode |
| --- | --- | --- | --- | --- |
| `eduroam` | `common/network/wifi/eduroam.age` | `/run/agenix/eduroam` | `wpa_supplicant:wpa_supplicant` | `0400` |
| `passwd_tsukumo` | `common/core/users/passwd_tsukumo.age` | `/run/agenix/passwd_tsukumo` | `root:root` | `0400` |
| `wifi-pwds` | `common/network/wifi/pwds.age` | `/run/agenix/wifi-pwds` | `wpa_supplicant:wpa_supplicant` | `0400` |

### Home secrets (`tsukumo`)

| Secret | File | Runtime | Home path | Mode |
| --- | --- | --- | --- | --- |
| `github_credential` | `common/shell/git/gh_hosts_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/github_credential` | `.config/gh/hosts.yml` | `0400` |
| `nix_access_tokens` | `common/shell/private/nix-access-tokens.age` | `${XDG_RUNTIME_DIR}/agenix/nix_access_tokens` | `.config/nix/access-tokens` | `0400` |
| `nowplaying_token` | `common/desktop/services/nowplaying/nowplaying-token.age` | `${XDG_RUNTIME_DIR}/agenix/nowplaying_token` | — | `0400` |
| `opencode_auth` | `common/dev/opencode/auth_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/opencode_auth` | `.local/share/opencode/auth.json` | `0400` |
| `ssh_key` | `common/shell/ssh/ssh-key_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/ssh_key` | `.ssh/id_ed25519` | `0400` |

## mouse-3

### System secrets

| Secret | File | Runtime | Owner:Group | Mode |
| --- | --- | --- | --- | --- |
| `cloudflared_nowplaying` | `hosts/mouse-3/secrets/cloudflared-nowplaying-credentials.age` | `/run/agenix/cloudflared_nowplaying` | `root:root` | `0400` |
| `passwd_tsukumo` | `common/core/users/passwd_tsukumo.age` | `/run/agenix/passwd_tsukumo` | `root:root` | `0400` |

### Home secrets (`tsukumo`)

| Secret | File | Runtime | Home path | Mode |
| --- | --- | --- | --- | --- |
| `github_credential` | `common/shell/git/gh_hosts_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/github_credential` | `.config/gh/hosts.yml` | `0400` |
| `nix_access_tokens` | `common/shell/private/nix-access-tokens.age` | `${XDG_RUNTIME_DIR}/agenix/nix_access_tokens` | `.config/nix/access-tokens` | `0400` |
| `nowplaying_token` | `common/desktop/services/nowplaying/nowplaying-token.age` | `${XDG_RUNTIME_DIR}/agenix/nowplaying_token` | — | `0400` |
| `opencode_auth` | `common/dev/opencode/auth_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/opencode_auth` | `.local/share/opencode/auth.json` | `0400` |
| `opencode_web_password` | `common/dev/opencode/opencode-web-password.age` | `${XDG_RUNTIME_DIR}/agenix/opencode_web_password` | — | `0400` |
| `ssh_key` | `common/shell/ssh/ssh-key_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/ssh_key` | `.ssh/id_ed25519` | `0400` |

## thinkpadx13-nix

### System secrets

| Secret | File | Runtime | Owner:Group | Mode |
| --- | --- | --- | --- | --- |
| `eduroam` | `common/network/wifi/eduroam.age` | `/run/agenix/eduroam` | `wpa_supplicant:wpa_supplicant` | `0400` |
| `passwd_tsukumo` | `common/core/users/passwd_tsukumo.age` | `/run/agenix/passwd_tsukumo` | `root:root` | `0400` |
| `wifi-pwds` | `common/network/wifi/pwds.age` | `/run/agenix/wifi-pwds` | `wpa_supplicant:wpa_supplicant` | `0400` |

### Home secrets (`tsukumo`)

| Secret | File | Runtime | Home path | Mode |
| --- | --- | --- | --- | --- |
| `github_credential` | `common/shell/git/gh_hosts_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/github_credential` | `.config/gh/hosts.yml` | `0400` |
| `nix_access_tokens` | `common/shell/private/nix-access-tokens.age` | `${XDG_RUNTIME_DIR}/agenix/nix_access_tokens` | `.config/nix/access-tokens` | `0400` |
| `nowplaying_token` | `common/desktop/services/nowplaying/nowplaying-token.age` | `${XDG_RUNTIME_DIR}/agenix/nowplaying_token` | — | `0400` |
| `opencode_auth` | `common/dev/opencode/auth_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/opencode_auth` | `.local/share/opencode/auth.json` | `0400` |
| `ssh_key` | `common/shell/ssh/ssh-key_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/ssh_key` | `.ssh/id_ed25519` | `0400` |

## yoga-book

### System secrets

| Secret | File | Runtime | Owner:Group | Mode |
| --- | --- | --- | --- | --- |
| `eduroam` | `common/network/wifi/eduroam.age` | `/run/agenix/eduroam` | `wpa_supplicant:wpa_supplicant` | `0400` |
| `passwd_tsukumo` | `common/core/users/passwd_tsukumo.age` | `/run/agenix/passwd_tsukumo` | `root:root` | `0400` |
| `wifi-pwds` | `common/network/wifi/pwds.age` | `/run/agenix/wifi-pwds` | `wpa_supplicant:wpa_supplicant` | `0400` |

### Home secrets (`tsukumo`)

| Secret | File | Runtime | Home path | Mode |
| --- | --- | --- | --- | --- |
| `github_credential` | `common/shell/git/gh_hosts_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/github_credential` | `.config/gh/hosts.yml` | `0400` |
| `nix_access_tokens` | `common/shell/private/nix-access-tokens.age` | `${XDG_RUNTIME_DIR}/agenix/nix_access_tokens` | `.config/nix/access-tokens` | `0400` |
| `nowplaying_token` | `common/desktop/services/nowplaying/nowplaying-token.age` | `${XDG_RUNTIME_DIR}/agenix/nowplaying_token` | — | `0400` |
| `opencode_auth` | `common/dev/opencode/auth_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/opencode_auth` | `.local/share/opencode/auth.json` | `0400` |
| `ssh_key` | `common/shell/ssh/ssh-key_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/ssh_key` | `.ssh/id_ed25519` | `0400` |
