#!/usr/bin/env bash
set -euo pipefail

# --- Utilities ---
info() { echo -e "\e[34m[INFO]\e[0m $*"; }
warn() { echo -e "\e[33m[WARN]\e[0m $*"; }
error() { echo -e "\e[31m[ERROR]\e[0m $*"; exit 1; }

confirm() {
    local prompt="$1"
    read -p "$prompt (y/N): " -n 1 -r
    echo
    [[ ${REPLY:-n} =~ ^[Yy]$ ]]
}

# --- Tools ---
SBCTL="sudo nix run nixpkgs#sbctl --"
TPM2_TOTP="sudo nix run nixpkgs#tpm2-totp --"
CHATTR="sudo nix shell nixpkgs#e2fsprogs -c chattr"

# --- Functions ---

setup_sbctl() {
    info "--- Secure Boot (sbctl) ---"
    local status
    status=$($SBCTL status)
    echo "$status"

    if ! echo "$status" | grep -q "Setup Mode:.*Enabled"; then
        info "Secure Boot は既にセットアップ済み（User Mode）です。登録処理をスキップします。"
        return 0
    fi

    if [ ! -f /var/lib/sbctl/keys/pk/PK.key ]; then
        info "Secure Boot キーを作成しています..."
        $SBCTL create-keys
    fi

    enroll_keys_with_retry
}

enroll_keys_with_retry() {
    info "キーを UEFI に登録します... (オプション: --microsoft --firmware-builtin)"
    
    # 1回目の試行
    if $SBCTL enroll-keys --microsoft --firmware-builtin; then
        info "Secure Boot キーとメーカー鍵の登録が完了しました。"
        return 0
    fi

    warn "登録に失敗しました。EFI変数が保護（immutable）されている可能性があります。"
    if confirm "EFI変数の保護を解除して再試行しますか？"; then
        $CHATTR -i /sys/firmware/efi/efivars/* || true
        if $SBCTL enroll-keys --microsoft --firmware-builtin; then
            info "Secure Boot キーとメーカー鍵の登録が完了しました。"
            return 0
        fi
        warn "再試行しましたが失敗しました。"
    fi

    if confirm "メーカー鍵を諦め、--microsoft のみで続行しますか？"; then
        $SBCTL enroll-keys --microsoft
        info "Microsoftの鍵と自前の鍵のみで登録しました。"
    else
        error "セットアップを中断しました。BIOS設定を確認してください。"
    fi
}

find_luks_device() {
    local root_dev
    root_dev=$(findmnt -no SOURCE / | sed 's/\[.*\]//' | xargs basename)

    # ルートデバイスの親から crypto_LUKS を探す
    local dev
    for dev in $(lsblk -apsno NAME,FSTYPE | grep -B 100 "$root_dev" | tac | awk '{print $1}'); do
        if [ "$(lsblk -dno FSTYPE "/dev/$dev" 2>/dev/null | xargs)" = "crypto_LUKS" ]; then
            echo "/dev/$dev"
            return 0
        fi
    done

    # 見つからない場合は fzf で選択
    warn "LUKS デバイスを自動特定できませんでした。"
    local selected
    selected=$(lsblk -pno NAME,FSTYPE | grep crypto_LUKS | nix run nixpkgs#fzf -- --height 40% --reverse --header "TPM2に登録するLUKSデバイスを選択してください" | awk '{print $1}' || true)
    if [ -n "$selected" ]; then
        echo "$selected" | sed 's/[^/]*\(\/dev\/.*\)/\1/'
        return 0
    fi

    return 1
}

setup_luks_tpm2() {
    info "--- TPM2 LUKS Enrollment ---"
    local luks_device
    luks_device=$(find_luks_device) || { warn "LUKS デバイスが見つかりませんでした。"; return 0; }

    local uuid
    uuid=$(lsblk -dno UUID "$luks_device")
    info "検出された LUKS デバイス: $luks_device (UUID: $uuid)"

    if confirm "このデバイスを TPM2 に登録しますか？"; then
        info "TPM2 登録を開始します。PCR 0+2+7 を使用し、PIN を設定します。"
        sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+2+7 --tpm2-with-pin=yes "/dev/disk/by-uuid/$uuid"
        info "TPM2 の登録が完了しました。"
    fi
}

setup_tpm2_totp() {
    info "--- TPM2 TOTP Setup ---"
    if confirm "TPM2 TOTP を初期化しますか？"; then
        $TPM2_TOTP generate
    fi
}

# --- Main ---

echo "=== Secure Boot & TPM2 Setup Script (OEM Key Preservation) ==="

setup_sbctl
setup_luks_tpm2
setup_tpm2_totp

echo -e "\n=== セットアップ完了 ==="
info "設定を反映させるために再起動してください。"
