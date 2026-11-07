# Secrets Access Matrix
Generated on 2026-11-07 21:51:32

> **GENERATED FILE** - do not edit manually.
> Regenerate with `pre-commit run gen-docs --all-files`.

## Legend

- Decrypted secrets are mode `0400`.
- System secrets are exposed at the runtime path shown.
- Home secrets are exposed at the runtime path shown; `Home path` is the optional symlink relative to the user's home (`—` means no symlink).
- System secrets are protected by DAC and `LoadCredential`. Dedicated service daemons (cloudflared, wpa_supplicant) get a profile limited to their system secrets.
- Home secrets are decrypted to user-owned runtime paths and are user-level. AppArmor does not isolate home secrets; they are marked accepted risk.
- Service profiles attach to `/nix/store/*/bin/<name>`; executables outside `bin` are not matched. Profiles are per executable basename.

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
| `github_credential` | `common/shell/git/gh_hosts_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/github_credential` | `.config/gh/hosts.yml` | — | — | accepted risk: `home secret; user-level (AppArmor not used)` |
| `nix_access_tokens` | `common/shell/private/nix-access-tokens.age` | `${XDG_RUNTIME_DIR}/agenix/nix_access_tokens` | `.config/nix/access-tokens` | — | — | accepted risk: `home secret; user-level (AppArmor not used)` |
| `nowplaying_token` | `common/desktop/services/nowplaying/nowplaying-token.age` | `${XDG_RUNTIME_DIR}/agenix/nowplaying_token` | — | `nowplaying-bridge` | — | accepted risk: `home secret; user-level (AppArmor not used)` |
| `opencode_auth` | `common/dev/opencode/auth_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/opencode_auth` | `.local/share/opencode/auth.json` | — | — | accepted risk: `home secret; user-level (AppArmor not used)` |
| `ssh_key` | `common/shell/ssh/ssh-key_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/ssh_key` | `.ssh/id_ed25519` | — | — | accepted risk: `home secret; user-level (AppArmor not used)` |

## mouse-3

### System secrets

| Secret | Kind | File | Runtime | Owner:Group | Consumers | Programs | Trust |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `cloudflared_nowplaying` | `credential` | `hosts/mouse-3/secrets/cloudflared-nowplaying-credentials.age` | `/run/agenix/cloudflared_nowplaying` | `root:root` | `cloudflared-tunnel-mouse-3` | `cloudflared` | trusted |
| `passwd_tsukumo` | `root` | `common/core/users/passwd_tsukumo.age` | `/run/agenix/passwd_tsukumo` | `root:root` | — | — | trusted |

### Home secrets (`tsukumo`)

| Secret | File | Runtime | Home path | Consumers | Programs | Trust |
| --- | --- | --- | --- | --- | --- | --- |
| `github_credential` | `common/shell/git/gh_hosts_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/github_credential` | `.config/gh/hosts.yml` | — | — | accepted risk: `home secret; user-level (AppArmor not used)` |
| `nix_access_tokens` | `common/shell/private/nix-access-tokens.age` | `${XDG_RUNTIME_DIR}/agenix/nix_access_tokens` | `.config/nix/access-tokens` | — | — | accepted risk: `home secret; user-level (AppArmor not used)` |
| `nowplaying_token` | `common/desktop/services/nowplaying/nowplaying-token.age` | `${XDG_RUNTIME_DIR}/agenix/nowplaying_token` | — | `podman-nowplaying` | — | accepted risk: `home secret; user-level (AppArmor not used)` |
| `opencode_auth` | `common/dev/opencode/auth_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/opencode_auth` | `.local/share/opencode/auth.json` | — | — | accepted risk: `home secret; user-level (AppArmor not used)` |
| `opencode_web_password` | `common/dev/opencode/opencode-web-password.age` | `${XDG_RUNTIME_DIR}/agenix/opencode_web_password` | — | `opencode-web` | — | accepted risk: `home secret; user-level (AppArmor not used)` |
| `ssh_key` | `common/shell/ssh/ssh-key_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/ssh_key` | `.ssh/id_ed25519` | — | — | accepted risk: `home secret; user-level (AppArmor not used)` |

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
| `github_credential` | `common/shell/git/gh_hosts_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/github_credential` | `.config/gh/hosts.yml` | — | — | accepted risk: `home secret; user-level (AppArmor not used)` |
| `nix_access_tokens` | `common/shell/private/nix-access-tokens.age` | `${XDG_RUNTIME_DIR}/agenix/nix_access_tokens` | `.config/nix/access-tokens` | — | — | accepted risk: `home secret; user-level (AppArmor not used)` |
| `nowplaying_token` | `common/desktop/services/nowplaying/nowplaying-token.age` | `${XDG_RUNTIME_DIR}/agenix/nowplaying_token` | — | `nowplaying-bridge` | — | accepted risk: `home secret; user-level (AppArmor not used)` |
| `opencode_auth` | `common/dev/opencode/auth_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/opencode_auth` | `.local/share/opencode/auth.json` | — | — | accepted risk: `home secret; user-level (AppArmor not used)` |
| `ssh_key` | `common/shell/ssh/ssh-key_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/ssh_key` | `.ssh/id_ed25519` | — | — | accepted risk: `home secret; user-level (AppArmor not used)` |

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
| `github_credential` | `common/shell/git/gh_hosts_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/github_credential` | `.config/gh/hosts.yml` | — | — | accepted risk: `home secret; user-level (AppArmor not used)` |
| `nix_access_tokens` | `common/shell/private/nix-access-tokens.age` | `${XDG_RUNTIME_DIR}/agenix/nix_access_tokens` | `.config/nix/access-tokens` | — | — | accepted risk: `home secret; user-level (AppArmor not used)` |
| `nowplaying_token` | `common/desktop/services/nowplaying/nowplaying-token.age` | `${XDG_RUNTIME_DIR}/agenix/nowplaying_token` | — | `nowplaying-bridge` | — | accepted risk: `home secret; user-level (AppArmor not used)` |
| `opencode_auth` | `common/dev/opencode/auth_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/opencode_auth` | `.local/share/opencode/auth.json` | — | — | accepted risk: `home secret; user-level (AppArmor not used)` |
| `ssh_key` | `common/shell/ssh/ssh-key_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/ssh_key` | `.ssh/id_ed25519` | — | — | accepted risk: `home secret; user-level (AppArmor not used)` |
