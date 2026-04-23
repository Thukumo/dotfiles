#!/usr/bin/env bash
set -euo pipefail

BUILD_ON_REMOTE=""
HOST_NAME=""
REMOTE=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --remote)
      BUILD_ON_REMOTE="--build-on remote"
      shift
      ;;
    -*)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
    *)
      if [[ -z "$HOST_NAME" ]]; then
        HOST_NAME="$1"
      elif [[ -z "$REMOTE" ]]; then
        REMOTE="$1"
      else
        echo "Too many arguments" >&2
        exit 1
      fi
      shift
      ;;
  esac
done

if [[ -z "$HOST_NAME" ]]; then
  echo "Usage: $0 [--remote] <host-name> [remote-host]" >&2
  echo "  remote-host: nixos@installer.local (default)" >&2
  exit 1
fi

REMOTE="${REMOTE:-nixos@installer.local}"
TARGET="${REMOTE#*@}"
# SSHオプション: known_hostsに追加せず、接続タイムアウトを設定
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null -o ConnectTimeout=5"

echo "Checking target: $TARGET"
# IPアドレスかどうかの簡易チェック（数字とドット、またはIPv6のコロンが含まれているか）
if [[ ! "$TARGET" =~ ^[0-9.]+$ ]] && [[ ! "$TARGET" =~ : ]]; then
  if ! getent hosts "$TARGET" >/dev/null 2>&1; then
    echo "Error: Target '$TARGET' cannot be resolved." >&2
    exit 1
  fi
fi

echo "Checking SSH connection to $REMOTE..."
if ! ssh $SSH_OPTS "$REMOTE" exit 2>/dev/null; then
  echo "Error: Cannot connect to $REMOTE via SSH. Please check the address and ensure SSH is enabled." >&2
  exit 1
fi

echo "Using remote: $REMOTE"
TMP_DIR="tmp"

cleanup() {
  rm -rf "$TMP_DIR"
}

trap cleanup EXIT

rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"/persist/etc/age
nix shell nixpkgs#rage -c rage-keygen -o "$TMP_DIR"/persist/etc/age/key.txt
chmod 600 "$TMP_DIR"/persist/etc/age/key.txt

# 公開鍵を抽出
PUBLIC_KEY=$(grep '# public key:' "$TMP_DIR"/persist/etc/age/key.txt | awk '{print $4}')
echo "生成された公開鍵: $PUBLIC_KEY"

# secrets.nixに自動追加（既存のキーがあれば削除してから追加）
sed -i "/^    \"$HOST_NAME\" = /d" secrets.nix
sed -i "/^  systemKeysAttr = {$/a\\    \"$HOST_NAME\" = \"$PUBLIC_KEY\";" secrets.nix

echo "secrets.nixに公開鍵を追加しました"
sudo ragenix -r -i "/etc/age/key.txt"
ssh $SSH_OPTS "$REMOTE" "nixos-generate-config --no-filesystems --show-hardware-config" > "hosts/${HOST_NAME}/hardware-configuration.nix"
git add "hosts/${HOST_NAME}/hardware-configuration.nix"
nix run --inputs-from . nixos-anywhere -- --extra-files "$TMP_DIR" $BUILD_ON_REMOTE --flake ".#${HOST_NAME}" --ssh-option StrictHostKeyChecking=no --ssh-option UserKnownHostsFile=/dev/null --ssh-option GlobalKnownHostsFile=/dev/null "$REMOTE"
