# Secrets Access Matrix
Generated on 2026-11-06 04:42:27

> **GENERATED FILE** - do not edit manually.
> Regenerate with `pre-commit run gen-docs --all-files`.

## Legend

- Decrypted secrets are mode `0400`.
- System secrets are exposed at the runtime path shown.
- Home secrets are exposed at the runtime path shown; `Home path` is the optional symlink relative to the user's home (`—` means no symlink).

## 16x-aurora

### System secrets

| Secret | Kind | File | Runtime | Owner:Group | Consumers | Programs | Trust |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `eduroam` | `owner` | `common/network/wifi/eduroam.age` | `/run/agenix/eduroam` | `wpa_supplicant:wpa_supplicant` | — | `wpa_supplicant` | trusted |
| `passwd_tsukumo` | `root` | `common/core/users/passwd_tsukumo.age` | `/run/agenix/passwd_tsukumo` | `root:root` | — | — | trusted |
| `sras-vpn` | `owner` | `common/network/sras-vpn/sras-vpn.age` | `/run/agenix/sras-vpn` | `tsukumo:users` | — | `vpn-sstp-connect` | trusted |
| `wifi-pwds` | `owner` | `common/network/wifi/pwds.age` | `/run/agenix/wifi-pwds` | `wpa_supplicant:wpa_supplicant` | — | `wpa_supplicant` | trusted |

### Home secrets (`tsukumo`)

| Secret | File | Runtime | Home path | Consumers | Programs | Trust |
| --- | --- | --- | --- | --- | --- | --- |
| `github_credential` | `common/shell/git/gh_hosts_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/github_credential` | `.config/gh/hosts.yml` | — | `gh` | trusted |
| `nix_access_tokens` | `common/shell/private/nix-access-tokens.age` | `${XDG_RUNTIME_DIR}/agenix/nix_access_tokens` | `.config/nix/access-tokens` | — | `nix` | trusted |
| `nowplaying_token` | `common/desktop/services/nowplaying/nowplaying-token.age` | `${XDG_RUNTIME_DIR}/agenix/nowplaying_token` | — | `nowplaying-bridge` | `nowplaying-client` | trusted |
| `opencode_auth` | `common/dev/opencode/auth_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/opencode_auth` | `.local/share/opencode/auth.json` | — | `opencode` | trusted |
| `ssh_key` | `common/shell/ssh/ssh-key_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/ssh_key` | `.ssh/id_ed25519` | — | `ssh`, `ssh-keygen` | trusted |

## mouse-3

### System secrets

| Secret | Kind | File | Runtime | Owner:Group | Consumers | Programs | Trust |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `cloudflared_nowplaying` | `credential` | `hosts/mouse-3/secrets/cloudflared-nowplaying-credentials.age` | `/run/agenix/cloudflared_nowplaying` | `root:root` | `cloudflared-tunnel-mouse-3` | `cloudflared` | trusted |
| `passwd_tsukumo` | `root` | `common/core/users/passwd_tsukumo.age` | `/run/agenix/passwd_tsukumo` | `root:root` | — | — | trusted |

### Home secrets (`tsukumo`)

| Secret | File | Runtime | Home path | Consumers | Programs | Trust |
| --- | --- | --- | --- | --- | --- | --- |
| `github_credential` | `common/shell/git/gh_hosts_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/github_credential` | `.config/gh/hosts.yml` | — | `gh` | trusted |
| `nix_access_tokens` | `common/shell/private/nix-access-tokens.age` | `${XDG_RUNTIME_DIR}/agenix/nix_access_tokens` | `.config/nix/access-tokens` | — | `nix` | trusted |
| `nowplaying_token` | `common/desktop/services/nowplaying/nowplaying-token.age` | `${XDG_RUNTIME_DIR}/agenix/nowplaying_token` | — | `podman-nowplaying` | `podman` | trusted |
| `opencode_auth` | `common/dev/opencode/auth_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/opencode_auth` | `.local/share/opencode/auth.json` | — | `opencode` | trusted |
| `opencode_web_password` | `common/dev/opencode/opencode-web-password.age` | `${XDG_RUNTIME_DIR}/agenix/opencode_web_password` | — | `opencode-web` | `opencode` | trusted |
| `ssh_key` | `common/shell/ssh/ssh-key_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/ssh_key` | `.ssh/id_ed25519` | — | `ssh`, `ssh-keygen` | trusted |

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
| `github_credential` | `common/shell/git/gh_hosts_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/github_credential` | `.config/gh/hosts.yml` | — | `gh` | trusted |
| `nix_access_tokens` | `common/shell/private/nix-access-tokens.age` | `${XDG_RUNTIME_DIR}/agenix/nix_access_tokens` | `.config/nix/access-tokens` | — | `nix` | trusted |
| `nowplaying_token` | `common/desktop/services/nowplaying/nowplaying-token.age` | `${XDG_RUNTIME_DIR}/agenix/nowplaying_token` | — | `nowplaying-bridge` | `nowplaying-client` | trusted |
| `opencode_auth` | `common/dev/opencode/auth_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/opencode_auth` | `.local/share/opencode/auth.json` | — | `opencode` | trusted |
| `ssh_key` | `common/shell/ssh/ssh-key_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/ssh_key` | `.ssh/id_ed25519` | — | `ssh`, `ssh-keygen` | trusted |

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
| `github_credential` | `common/shell/git/gh_hosts_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/github_credential` | `.config/gh/hosts.yml` | — | `gh` | trusted |
| `nix_access_tokens` | `common/shell/private/nix-access-tokens.age` | `${XDG_RUNTIME_DIR}/agenix/nix_access_tokens` | `.config/nix/access-tokens` | — | `nix` | trusted |
| `nowplaying_token` | `common/desktop/services/nowplaying/nowplaying-token.age` | `${XDG_RUNTIME_DIR}/agenix/nowplaying_token` | — | `nowplaying-bridge` | `nowplaying-client` | trusted |
| `opencode_auth` | `common/dev/opencode/auth_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/opencode_auth` | `.local/share/opencode/auth.json` | — | `opencode` | trusted |
| `ssh_key` | `common/shell/ssh/ssh-key_tsukumo.age` | `${XDG_RUNTIME_DIR}/agenix/ssh_key` | `.ssh/id_ed25519` | — | `ssh`, `ssh-keygen` | trusted |
