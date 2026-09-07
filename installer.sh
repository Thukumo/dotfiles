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
SECRETS_OLD="$(mktemp)"
FAILED_LIST="$(mktemp)"

cleanup() {
  rm -rf "$TMP_DIR"
  [[ -n "${SECRETS_OLD:-}" ]] && rm -f "$SECRETS_OLD"
  [[ -n "${FAILED_LIST:-}" ]] && rm -f "$FAILED_LIST"
}

trap cleanup EXIT

rm -rf "$TMP_DIR"

# hardware-configuration はフレーク評価に必要なので先に生成する
ssh $SSH_OPTS "$REMOTE" "nixos-generate-config --no-filesystems --show-hardware-config" > "hosts/${HOST_NAME}/hardware-configuration.nix"
git add "hosts/${HOST_NAME}/hardware-configuration.nix"

# ホームキーを配置するユーザー (home-manager のユーザー) を取得する
USER_NAME=$(nix eval --raw --apply 'users: builtins.head (builtins.attrNames users)' ".#nixosConfigurations.${HOST_NAME}.config.home-manager.users")

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
# (出力はフックと同じく nixfmt をかける)
# 中断後に再実行した場合、worktree の secrets.nix は再生成済みになっているため、
# ベースラインはコミット済み版を使う (そうしないと diff が空になり rekey がスキップされる)
BASELINE_ARGS=()
if git show HEAD:secrets.nix >"$SECRETS_OLD" 2>/dev/null; then
  BASELINE_ARGS=(--old "$SECRETS_OLD")
else
  echo "警告: ベースライン (git HEAD の secrets.nix) を取得できないため、全秘密を再暗号化します" >&2
fi
nix eval --raw --apply 'x: x.render x.hostsData x.keys' .#genSecrets \
  | nix shell nixpkgs#nixfmt -c nixfmt - > secrets.nix

LOCAL_KEY_ARGS=()
if [[ -f "/etc/age/key.txt" ]]; then
  LOCAL_KEY_ARGS+=(-i "/etc/age/key.txt")
fi
if [[ -f "$HOME/.config/age/home-manager_key" ]]; then
  LOCAL_KEY_ARGS+=(-i "$HOME/.config/age/home-manager_key")
elif [[ -f "/persist/home/$USER/.config/age/home-manager_key" ]]; then
  LOCAL_KEY_ARGS+=(-i "/persist/home/$USER/.config/age/home-manager_key")
elif [[ -f "/persist/home/$USER_NAME/.config/age/home-manager_key" ]]; then
  LOCAL_KEY_ARGS+=(-i "/persist/home/$USER_NAME/.config/age/home-manager_key")
fi

if ! sudo ./rekey.sh "${BASELINE_ARGS[@]}" --failed-out "$FAILED_LIST" "${LOCAL_KEY_ARGS[@]}"; then
  echo "error: ローカルの鍵では rekey できない秘密があります" >&2
  echo "次の手順を手動で実行してください:" >&2
  echo "  1. 変更を commit + push (secrets.nix が更新されているため --no-verify が必要):" >&2
  echo "     git add -A && git commit --no-verify -m rekey && git push" >&2
  echo "  2. 以下の秘密を参照ホストで rekey (各ファイル、いずれか 1 台で可。参照ホストは上記の rekey.sh 出力を参照):" >&2
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    echo "  $f" >&2
  done <"$FAILED_LIST"
  echo "  3. 完了したら Enter (installer が git pull して新ホストの鍵で検証します)" >&2
  if ! read -r; then
    echo "error: 標準入力が閉じています。参照ホストでの rekey 手順を完了してから再実行してください" >&2
    exit 1
  fi
  if ! git pull; then
    echo "error: git pull に失敗しました" >&2
    exit 1
  fi
  unresolved=()
  RAGE=(rage)
  if ! command -v rage >/dev/null 2>&1; then
    RAGE=(nix shell nixpkgs#rage -c rage)
  fi
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    if [[ ! -f "$f" ]]; then
      echo "skipped (pull 後に対象ファイルが存在しません。リネーム等で対象外になった可能性): $f" >&2
      continue
    fi
    if ! "${RAGE[@]}" -d \
      -i "$TMP_DIR/persist/etc/age/key.txt" \
      -i "$TMP_DIR/persist/home/$USER_NAME/.config/age/home-manager_key" \
      "$f" >/dev/null 2>&1; then
      unresolved+=("$f")
    fi
  done <"$FAILED_LIST"
  if [[ ${#unresolved[@]} -gt 0 ]]; then
    echo "error: 以下の秘密は新ホストの鍵でまだ復号できません。参照ホストでの rekey が完了しているか確認してください" >&2
    printf '  %s\n' "${unresolved[@]}" >&2
    exit 1
  fi
  echo "すべての秘密が新ホストの鍵で復号できることを確認しました" >&2
fi

nix run --inputs-from . nixos-anywhere -- --extra-files "$TMP_DIR" $BUILD_ON_REMOTE --flake ".#${HOST_NAME}" --ssh-option StrictHostKeyChecking=no --ssh-option UserKnownHostsFile=/dev/null --ssh-option GlobalKnownHostsFile=/dev/null "$REMOTE"
