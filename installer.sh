#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <host-name> [remote-host]" >&2
  echo "  remote-host: nixos@installer.local (default)" >&2
  exit 1
fi

HOST_NAME="$1"
REMOTE="${2:-nixos@installer.local}"
TARGET="${REMOTE#*@}"
TMP_DIR="tmp"

cleanup() {
  rm -rf "$TMP_DIR"
}

trap cleanup EXIT

# known_hostsから登録を削除
ssh-keygen -R "$TARGET" 2>/dev/null || true

rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"/persist/etc/age
nix shell nixpkgs#rage -c rage-keygen -o "$TMP_DIR"/persist/etc/age/key.txt
chmod 600 "$TMP_DIR"/persist/etc/age/key.txt

# 公開鍵を抽出
PUBLIC_KEY=$(grep '# public key:' "$TMP_DIR"/persist/etc/age/key.txt | awk '{print $4}')
echo "生成された公開鍵: $PUBLIC_KEY"

# secrets.nixに自動追加（既存のキーがあれば削除してから追加）
sed -i "/^    \"$HOST_NAME\" = /d" secrets.nix
sed -i "/^  keys = {$/a\\    \"$HOST_NAME\" = \"$PUBLIC_KEY\";" secrets.nix

echo "secrets.nixに公開鍵を追加しました"
sudo ragenix -r -i "/etc/age/key.txt"
ssh "$REMOTE" "nixos-generate-config --no-filesystems --show-hardware-config" > "hosts/${HOST_NAME}/hardware-configuration.nix"
git add "hosts/${HOST_NAME}/hardware-configuration.nix"
nix run --inputs-from . nixos-anywhere -- --extra-files "$TMP_DIR" --flake ".#${HOST_NAME}" "$REMOTE"
