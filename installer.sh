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

# hardware-configuration はフレーク評価に必要なので先に生成する
ssh $SSH_OPTS "$REMOTE" "nixos-generate-config --no-filesystems --show-hardware-config" > "hosts/${HOST_NAME}/hardware-configuration.nix"
git add "hosts/${HOST_NAME}/hardware-configuration.nix"

# ホームキーを配置するユーザー (home-manager のユーザー) を取得する
USER_NAME=$(nix eval --raw --apply 'users: builtins.attrNames users' ".#nixosConfigurations.${HOST_NAME}.config.home-manager.users" | awk '{print $1}')

mkdir -p "$TMP_DIR"/persist/etc/age "$TMP_DIR"/persist/home/"$USER_NAME"/.config/age
nix shell nixpkgs#rage -c rage-keygen -o "$TMP_DIR"/persist/etc/age/key.txt
nix shell nixpkgs#rage -c rage-keygen -o "$TMP_DIR"/persist/home/"$USER_NAME"/.config/age/home-manager_key
chmod 600 "$TMP_DIR"/persist/etc/age/key.txt "$TMP_DIR"/persist/home/"$USER_NAME"/.config/age/home-manager_key

# 公開鍵を抽出
SYSTEM_PUBLIC_KEY=$(grep '# public key:' "$TMP_DIR"/persist/etc/age/key.txt | awk '{print $4}')
HOME_PUBLIC_KEY=$(grep '# public key:' "$TMP_DIR"/persist/home/"$USER_NAME"/.config/age/home-manager_key | awk '{print $4}')
echo "生成されたシステム公開鍵: $SYSTEM_PUBLIC_KEY"
echo "生成されたホーム公開鍵: $HOME_PUBLIC_KEY"

# keys.nixに自動追加（既存のキーがあれば削除してから追加）
sed -i "/^    \"$HOST_NAME\" = /d" keys.nix
sed -i "/^  systemKeys = {$/a\\    \"$HOST_NAME\" = \"$SYSTEM_PUBLIC_KEY\";" keys.nix
sed -i "/^      \"$HOST_NAME\" = /d" keys.nix
sed -i "/^    \"$USER_NAME\" = {$/a\\      \"$HOST_NAME\" = \"$HOME_PUBLIC_KEY\";" keys.nix

echo "keys.nixに公開鍵を追加しました"

# secrets.nix を再生成して、新しいホストが必要とする秘密にキーを追加する
nix eval --raw --apply 'x: x.render x.hostsData x.keys' .#genSecrets > secrets.nix

# 再暗号化。このマシンのキーで解けない秘密 (他ホスト専用の秘密) がある場合は
# ragenix がエラーで中断するため、必要なら該当ホスト上で rekey する
if ! sudo ragenix -r -i "/etc/age/key.txt" -i "/persist/home/$USER_NAME/.config/age/home-manager_key"; then
  echo "警告: 一部の秘密を rekey できませんでした。該当ホスト上で 'ragenix -r -i <そのホストのキー>' を実行してください" >&2
fi

nix run --inputs-from . nixos-anywhere -- --extra-files "$TMP_DIR" $BUILD_ON_REMOTE --flake ".#${HOST_NAME}" --ssh-option StrictHostKeyChecking=no --ssh-option UserKnownHostsFile=/dev/null --ssh-option GlobalKnownHostsFile=/dev/null "$REMOTE"
