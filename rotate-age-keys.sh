#!/usr/bin/env bash
set -euo pipefail

# rotate-age-keys.sh — ホストの age 鍵 (key.txt) をローテーションする
#
# 使い方:
#   ./rotate-age-keys.sh <host> [--user USER] [--no-deploy] [--yes]
#
# 流れ (旧鍵で復号できるうちに rekey してから新鍵を配備する):
#   1. 新鍵を tmp/rotate-<host>/ に生成 (gitignore 済み、失敗時リトライ用に残す)
#   2. keys.nix の公開鍵を更新 → secrets.nix を再生成
#   3. ./rekey.sh --files で再暗号化 (対象は当該ホストの鍵を参照する秘密。復号には手元の旧鍵を使う)
#   4. 新鍵で復号できることを検証してからこのホストに配備 (sudo install)
#
# rekey に失敗したら中断する (新鍵は配備しない)。表示される手順で
# 参照ホスト側の rekey を済ませてから再実行すること。再実行時は残っている
# tmp/rotate-<host>/ の新鍵をそのまま使うので、鍵ペアは変わらない。

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

HOST=""
USER_NAME=""
NO_DEPLOY=0
YES=0

usage() {
  cat >&2 <<EOF
Usage: $0 <host> [--user USER] [--no-deploy] [--yes]
  --user USER     home-manager のユーザー (既定: flake から取得)
  --no-deploy     rekey まで (新鍵は tmp/rotate-<host>/ に残す)
  --yes           確認なしで実行
EOF
  exit 1
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --user) [[ -n "${2:-}" ]] || usage; USER_NAME="$2"; shift 2 ;;
    --no-deploy) NO_DEPLOY=1; shift ;;
    --yes | -y) YES=1; shift ;;
    -h | --help) usage ;;
    -*)
      echo "Unknown option: $1" >&2
      usage
      ;;
    *)
      if [[ -z "$HOST" ]]; then
        HOST="$1"
      else
        echo "Too many arguments" >&2
        usage
      fi
      shift
      ;;
  esac
done

[[ -z "$HOST" ]] && usage

if [[ -z "$USER_NAME" ]]; then
  USER_NAME=$(nix eval --raw --apply 'users: builtins.head (builtins.attrNames users)' ".#nixosConfigurations.${HOST}.config.home-manager.users")
fi
echo "host: $HOST, user: $USER_NAME"

STAGE="tmp/rotate-$HOST"
mkdir -p "$STAGE"
FAILED_LIST="$(mktemp)"
trap 'rm -f "$FAILED_LIST"' EXIT

KEYGEN=(rage-keygen)
RAGE=(rage)
if ! command -v rage >/dev/null 2>&1; then
  KEYGEN=(nix shell nixpkgs#rage -c rage-keygen)
  RAGE=(nix shell nixpkgs#rage -c rage)
fi

gen_key() { # $1=out: 既存なら再利用 (リトライ時に鍵ペアを変えない)
  if [[ -f "$1" ]]; then
    echo "reuse: $1"
  else
    "${KEYGEN[@]}" -o "$1"
    chmod 600 "$1"
    echo "generated: $1"
  fi
}

sort_keys_nix() { # $1=file: systemKeys / 各ユーザーブロック内のエントリ行をソート (先頭挿入の順序崩れ防止)
  local file="$1"
  local tmp
  tmp="$(mktemp)"
  local -a buf=()
  local inblock=0
  flush() {
    [[ ${#buf[@]} -gt 0 ]] && printf '%s\n' "${buf[@]}" | LC_ALL=C sort
    buf=()
  }
  {
    while IFS= read -r line || [[ -n "$line" ]]; do
      case "$line" in
        '  systemKeys = {' | '    "'*'" = {')
          inblock=1
          printf '%s\n' "$line"
          ;;
        '  };' | '    };')
          flush
          inblock=0
          printf '%s\n' "$line"
          ;;
        *)
          if ((inblock)) && [[ "$line" == *'"'* ]]; then
            buf+=("$line")
          else
            printf '%s\n' "$line"
          fi
          ;;
      esac
    done <"$file"
    flush
  } >"$tmp"
  cat "$tmp" >"$file"
  rm -f "$tmp"
}

gen_key "$STAGE/key.txt"
gen_key "$STAGE/home-manager_key"

NEW_SYSTEM_PUB=$(grep '# public key:' "$STAGE/key.txt" | awk '{print $4}')
NEW_HOME_PUB=$(grep '# public key:' "$STAGE/home-manager_key" | awk '{print $4}')
echo "new system pubkey: $NEW_SYSTEM_PUB"
echo "new home pubkey: $NEW_HOME_PUB"
if [[ -z "$NEW_SYSTEM_PUB" ]]; then
  echo "error: 公開鍵を取得できませんでした: $STAGE/key.txt" >&2
  exit 1
fi
if [[ -z "$NEW_HOME_PUB" ]]; then
  echo "error: 公開鍵を取得できませんでした: $STAGE/home-manager_key" >&2
  exit 1
fi

if [[ "$YES" != 1 ]]; then
  if [[ "$NO_DEPLOY" == 1 ]]; then
    echo "keys.nix と secrets.nix を更新し、rekey します (配備なし)。続行しますか? [y/N]"
  else
    echo "keys.nix と secrets.nix を更新し、rekey 後に ${HOST} へ配備します。続行しますか? [y/N]"
  fi
  read -r ans
  [[ "$ans" == y || "$ans" == Y ]] || exit 1
fi

cp keys.nix "$STAGE/keys.nix.bak"
sed -i "/^    \"$HOST\" = /d" keys.nix
# shellcheck disable=SC2016
sed -i '/^  systemKeys = {$/a\    "'"$HOST"'" = "'"$NEW_SYSTEM_PUB"'";' keys.nix
sed -i "/^    \"$USER_NAME\" = {\$/,/^    }/ { /^      \"$HOST\" = /d }" keys.nix
# shellcheck disable=SC2016
sed -i '/^    "'"$USER_NAME"'" = {$/a\      "'"$HOST"'" = "'"$NEW_HOME_PUB"'";' keys.nix
sort_keys_nix keys.nix
grep -q "^    \"$HOST\" = \"$NEW_SYSTEM_PUB\";$" keys.nix || {
  echo "error: keys.nix の systemKeys 更新に失敗しました" >&2
  exit 1
}
grep -q "^      \"$HOST\" = \"$NEW_HOME_PUB\";$" keys.nix || {
  echo "error: keys.nix の homeKeys 更新に失敗しました (user ブロック '$USER_NAME' がない可能性)" >&2
  exit 1
}

[[ -f secrets.nix ]] && cp secrets.nix "$STAGE/secrets.nix.bak"
nix eval --raw --apply 'x: x.render x.hostsData x.keys' .#genSecrets \
  | nix shell nixpkgs#nixfmt -c nixfmt - >"$STAGE/secrets.nix.new"
mv "$STAGE/secrets.nix.new" secrets.nix
echo "regenerated secrets.nix"

LOCAL_KEY_ARGS=()
[[ -f "/etc/age/key.txt" ]] && LOCAL_KEY_ARGS+=(-i "/etc/age/key.txt")
if [[ -f "$HOME/.config/age/home-manager_key" ]]; then
  LOCAL_KEY_ARGS+=(-i "$HOME/.config/age/home-manager_key")
elif [[ -n "${USER:-}" && -f "/persist/home/$USER/.config/age/home-manager_key" ]]; then
  LOCAL_KEY_ARGS+=(-i "/persist/home/$USER/.config/age/home-manager_key")
fi
if [[ ${#LOCAL_KEY_ARGS[@]} -eq 0 ]]; then
  echo "error: 復号用の鍵が見つかりません (-i /etc/age/key.txt などを用意してください)" >&2
  exit 1
fi

REKEY=(./rekey.sh)
if [[ $EUID -ne 0 && -f "/etc/age/key.txt" ]]; then
  REKEY=(sudo ./rekey.sh)
fi
# secrets.nix は鍵の参照式で書かれるため、鍵の値だけの変更は差分に出ない。
# 当該ホストの鍵式を含む秘密を列挙して --files で渡す
mapfile -t REKEY_TARGETS < <(awk -v s="keys.systemKeys.\"${HOST}\"" -v h="keys.homeKeys.\"${USER_NAME}\".\"${HOST}\"" '
  /\.publicKeys = \[/ {
    p = $0
    sub(/^[[:space:]]*"/, "", p)
    sub(/"\.publicKeys.*$/, "", p)
    cur = p
    if (index($0, s) || index($0, h)) seen[cur] = 1
    next
  }
  cur != "" {
    if (index($0, s) || index($0, h)) seen[cur] = 1
    if ($0 ~ /^[[:space:]]*\];/) cur = ""
  }
  END { for (f in seen) print f }
' secrets.nix | LC_ALL=C sort)
if [[ ${#REKEY_TARGETS[@]} -eq 0 ]]; then
  echo "rekey: $HOST の鍵を参照する秘密はないためスキップします"
elif ! "${REKEY[@]}" --files "${REKEY_TARGETS[@]}" --failed-out "$FAILED_LIST" "${LOCAL_KEY_ARGS[@]}"; then
  echo "error: 手元の鍵では rekey できない秘密があります。新鍵は配備していません" >&2
  echo "  新鍵は $STAGE/ に残してあるので、以下を済ませてから再実行してください (鍵ペアは再利用されます):" >&2
  echo "  1. git add -A && git commit --no-verify -m rekey && git push" >&2
  echo "  2. 参照ホストで git pull 後に sudo ./rekey.sh --files <対象> -i /etc/age/key.txt -i ~/.config/age/home-manager_key" >&2
  exit 1
fi

# ponytail: 全ホスト共通の定番2ファイルで疎通確認 (なければスキップ)
check_decrypt() { # $1=identity $2=.age
  [[ -f "$2" ]] || {
    echo "skip verify (not found): $2"
    return 0
  }
  "${RAGE[@]}" -d -i "$1" "$2" >/dev/null && echo "verified: $2"
}
check_decrypt "$STAGE/key.txt" "common/core/users/passwd_${USER_NAME}.age"
check_decrypt "$STAGE/home-manager_key" "common/shell/ssh/ssh-key_${USER_NAME}.age"

if [[ "$NO_DEPLOY" == 1 ]]; then
  echo "done (no-deploy): 新鍵は $STAGE/ にあります。配備は手動で行ってください"
  exit 0
fi

SYSTEM_DEST="/persist/etc/age/key.txt"
HOME_DEST="/persist/home/$USER_NAME/.config/age/home-manager_key"

deploy_one() { # $1=src $2=dest $3=owner-arg("root" or "user")
  local src="$1" dest="$2" owner="$3"
  local backup
  backup="$STAGE/old-$(basename "$src").bak"
  # shellcheck disable=SC2024 # sudo は読む側のみ。書き先は tmp/ の自所有ファイル
  if [[ -f "$dest" ]]; then sudo cat "$dest" >"$backup" 2>/dev/null || true; fi
  if [[ "$owner" == root ]]; then
    sudo install -D -m 600 "$src" "$dest"
  else
    sudo install -D -m 600 -o "$USER_NAME" -g users "$src" "$dest"
  fi
  echo "installed: $dest (old backup: $backup)"
}

deploy_one "$STAGE/key.txt" "$SYSTEM_DEST" root
deploy_one "$STAGE/home-manager_key" "$HOME_DEST" user

cat <<EOF
done.
  旧鍵の退避: $STAGE/old-*.bak (動作確認後に削除)
  新鍵の正本: 配備先ホスト上のみ。$STAGE/ の新鍵も確認後に削除推奨
  次に: git add -A && git commit --no-verify -m "rotate $HOST keys" && nixos-rebuild switch --flake .#$HOST
EOF
