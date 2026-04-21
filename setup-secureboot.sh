#!/usr/bin/env bash
set -e

echo "=== Secure Boot & TPM2 Setup Script (OEM Key Preservation) ==="

# 1. sbctl の状態確認とキー作成
if command -v sbctl > /dev/null; then
    echo "--- Secure Boot (sbctl) ---"
    sudo sbctl status
    
    if [ ! -f /var/lib/sbctl/keys/pk/PK.key ]; then
        echo "Secure Boot キーを生成します..."
        sudo sbctl create-keys
        
        echo "キーを UEFI に登録します..."
        echo "オプション: --microsoft --builtins (メーカー鍵の保持を試みます)"
        
        # --builtins が失敗する場合に備え、エラーハンドリング
        if sudo sbctl enroll-keys --microsoft --builtins; then
            echo "Secure Boot キーとメーカー鍵の登録が完了しました。"
        else
            echo "警告: --builtins を使用した登録に失敗しました。"
            echo "ファームウェアが既存の鍵の読み取りを許可していない可能性があります。"
            read -p "メーカー鍵を諦め、--microsoft のみで続行しますか？ (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                sudo sbctl enroll-keys --microsoft
                echo "Microsoftの鍵と自前の鍵のみで登録しました。"
            else
                echo "セットアップを中断しました。BIOS設定を確認してください。"
                exit 1
            fi
        fi
    else
        echo "Secure Boot キーは既に生成されています。"
    fi
else
    echo "sbctl が見つかりません。Lanzaboote の設定が有効か確認してください。"
fi

# 2. TPM2 LUKS 解読設定
echo -e "\n--- TPM2 LUKS Enrollment ---"
# root パーティションの LUKS デバイスを特定
LUKS_DEVICE=$(findmnt -no SOURCE / | xargs lsblk -no PKNAME | grep -v '^$')

if [ -n "$LUKS_DEVICE" ]; then
    UUID=$(lsblk -no UUID "/dev/$LUKS_DEVICE")
    echo "検出された LUKS デバイス: /dev/$LUKS_DEVICE (UUID: $UUID)"
    
    read -p "このデバイスを TPM2 に登録しますか？ (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "TPM2 登録を開始します。PCR 0+2+7 を使用し、PIN を設定します。"
        sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+2+7 --tpm2-with-pin=yes "/dev/disk/by-uuid/$UUID"
        echo "TPM2 の登録が完了しました。"
    fi
else
    echo "LUKS デバイスを自動特定できませんでした。"
fi

# 3. TPM2 TOTP 初期化
if command -v tpm2-totp > /dev/null; then
    echo -e "\n--- TPM2 TOTP Setup ---"
    read -p "TPM2 TOTP を初期化しますか？ (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo tpm2-totp init
    fi
fi

echo -e "\n=== セットアップ完了 ==="
echo "設定を反映させるために再起動してください。"
