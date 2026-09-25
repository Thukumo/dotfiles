#!/usr/bin/env bash
set -euo pipefail

# rekey.sh — secrets.nix の差分で必要な秘密だけを per-file で再暗号化する
#
# 使い方:
#   rekey.sh [--old FILE] [--new FILE] [-i IDENTITY]... [--all]
#   rekey.sh --files <path>... [-i IDENTITY]...
#
# ragenix -r は全秘密を再暗号化し、1 つでも復号できないファイルがあるとそこで
# 中断してしまう。このスクリプトは古い secrets.nix との差分から対象を絞り、
# ファイルごとに独立して `ragenix -r --rules <一時ファイル>` を実行するため、
# 失敗が他のファイルに波及しない。

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

OLD=""
OLD_KEYS_ARG=""
NEW="$SCRIPT_DIR/secrets.nix"
IDENTITIES=()
ALL=0
FILES_ARG=()
FAILED_OUT=""
TMP_FILES=()

cleanup() {
  if [[ ${#TMP_FILES[@]} -gt 0 ]]; then
    rm -f "${TMP_FILES[@]}"
  fi
}
trap cleanup EXIT

fail() {
  echo "error: $*" >&2
  exit 1
}

usage() {
  cat >&2 <<EOF
Usage: $0 [--old FILE] [--new FILE] [-i IDENTITY]... [--all]
       $0 --files <path>... [-i IDENTITY]...
  --old FILE      変更前の secrets.nix (デフォルト: git HEAD の secrets.nix)
  --old-keys FILE 変更前の keys.nix (デフォルト: git HEAD の keys.nix)
  --new FILE      変更後の secrets.nix (デフォルト: ./secrets.nix)
  -i IDENTITY     復号用の age 鍵 (繰り返し可)
  --all           差分を無視して全秘密を再暗号化
  --files         差分を無視して指定した秘密だけを再暗号化
  --failed-out    rekey できなかったファイルの相対パスを書き出すファイル
EOF
  exit 1
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --old) OLD="$2"; shift 2 ;;
    --old-keys) OLD_KEYS_ARG="$2"; shift 2 ;;
    --new) NEW="$2"; shift 2 ;;
    -i) IDENTITIES+=("$2"); shift 2 ;;
    --all) ALL=1; shift ;;
    --files)
      shift
      while [[ $# -gt 0 && "$1" != -* ]]; do
        FILES_ARG+=("$1")
        shift
      done
      ;;
    --failed-out) FAILED_OUT="$2"; shift 2 ;;
    -h | --help) usage ;;
    *) echo "Unknown option: $1" >&2; usage ;;
  esac
done

if [[ ! -f "$NEW" ]]; then
  fail "rules file not found: $NEW"
fi

# 差分モードでのみ古い secrets.nix が必要 (sudo 実行時も安全に読めるよう safe.directory を明示)
if [[ ${#FILES_ARG[@]} -eq 0 && -z "$OLD" ]]; then
  if git -C "$SCRIPT_DIR" -c safe.directory="$SCRIPT_DIR" cat-file -e HEAD:secrets.nix >/dev/null 2>&1; then
    OLD="$(mktemp)"
    TMP_FILES+=("$OLD")
    git -C "$SCRIPT_DIR" -c safe.directory="$SCRIPT_DIR" show HEAD:secrets.nix >"$OLD"
  fi
fi

# keys.nix の値だけの変更は secrets.nix の差分に出ない (参照式で書かれるため) ので、
# 差分モードでは keys.nix の新旧も比較する
KEYS_NEW="$SCRIPT_DIR/keys.nix"
OLD_KEYS_FILE=""
if [[ ${#FILES_ARG[@]} -eq 0 && "$ALL" == 0 ]]; then
  if [[ -n "$OLD_KEYS_ARG" ]]; then
    [[ -f "$OLD_KEYS_ARG" ]] || fail "old keys file not found: $OLD_KEYS_ARG"
    OLD_KEYS_FILE="$OLD_KEYS_ARG"
  elif git -C "$SCRIPT_DIR" -c safe.directory="$SCRIPT_DIR" cat-file -e HEAD:keys.nix >/dev/null 2>&1; then
    OLD_KEYS_FILE="$(mktemp)"
    TMP_FILES+=("$OLD_KEYS_FILE")
    git -C "$SCRIPT_DIR" -c safe.directory="$SCRIPT_DIR" show HEAD:keys.nix >"$OLD_KEYS_FILE"
  fi
fi
# secrets.nix から "path" ごとのキー式を抽出する (複数行/単一行の両形式に対応)
# 出力: path<TAB>key (1 行に 1 キー)
extract_keys() {
  awk '
    /^[[:space:]]*"[^"]+"\.publicKeys = \[.*\];[[:space:]]*$/ {
      p = $0
      sub(/^[[:space:]]*"/, "", p)
      sub(/"\.publicKeys = .*$/, "", p)
      s = $0
      sub(/^[[:space:]]*"[^"]+"\.publicKeys = \[[[:space:]]*/, "", s)
      sub(/[[:space:]]*\];[[:space:]]*$/, "", s)
      n = split(s, arr, /[[:space:]]+/)
      for (i = 1; i <= n; i++) if (arr[i] != "") printf "%s\t%s\n", p, arr[i]
      next
    }
    /^[[:space:]]*"[^"]+"\.publicKeys = \[[[:space:]]*$/ {
      p = $0
      sub(/^[[:space:]]*"/, "", p)
      sub(/"\.publicKeys = \[[[:space:]]*$/, "", p)
      in_block = 1
      next
    }
    in_block {
      if ($0 ~ /^[[:space:]]*\];[[:space:]]*$/) {
        in_block = 0
      } else {
        gsub(/^[[:space:]]+|[[:space:]]+$/, "")
        if ($0 != "") printf "%s\t%s\n", p, $0
      }
    }
  ' "$1"
}

# keys.nix からキー式ごとの値を抽出する (secrets.nix の参照式と表記を合わせる)
# 出力: key-expr<TAB>value (例: keys.homeKeys."tsukumo"."thinkpadx13-nix")
extract_key_values() {
  awk '
    /systemKeys = \{/ { in_sys = 1; next }
    in_sys && /^[[:space:]]*\};/ { in_sys = 0; next }
    in_sys {
      if (match($0, /"[^"]+"[[:space:]]*=[[:space:]]*"[^"]+"/)) {
        kv = substr($0, RSTART, RLENGTH)
        q1 = index(kv, "\"")
        r1 = substr(kv, q1 + 1)
        q2 = index(r1, "\"")
        name = substr(r1, 1, q2 - 1)
        vp = substr(kv, index(kv, "=") + 1)
        wr = substr(vp, index(vp, "\"") + 1)
        val = substr(wr, 1, index(wr, "\"") - 1)
        printf "keys.systemKeys.\"%s\"\t%s\n", name, val
      }
      next
    }
    /homeKeys = \{/ { in_home = 1; next }
    in_home && /^[[:space:]]*\};/ {
      if (in_user) { in_user = 0; cur_user = "" } else { in_home = 0 }
      next
    }
    in_home && !in_user && /=[[:space:]]*\{/ {
      ur = substr($0, index($0, "\"") + 1)
      cur_user = substr(ur, 1, index(ur, "\"") - 1)
      in_user = 1
      next
    }
    in_user {
      if (match($0, /"[^"]+"[[:space:]]*=[[:space:]]*"[^"]+"/)) {
        kv = substr($0, RSTART, RLENGTH)
        q1 = index(kv, "\"")
        r1 = substr(kv, q1 + 1)
        q2 = index(r1, "\"")
        name = substr(r1, 1, q2 - 1)
        vp = substr(kv, index(kv, "=") + 1)
        wr = substr(vp, index(vp, "\"") + 1)
        val = substr(wr, 1, index(wr, "\"") - 1)
        printf "keys.homeKeys.\"%s\".\"%s\"\t%s\n", cur_user, name, val
      }
      next
    }
  ' "$1"
}

declare -A OLD_KEYS NEW_KEYS
if [[ -n "$OLD" ]]; then
  while IFS=$'\t' read -r p k; do
    OLD_KEYS["$p"]+="$k"$'\n'
  done < <(extract_keys "$OLD")
fi
while IFS=$'\t' read -r p k; do
  NEW_KEYS["$p"]+="$k"$'\n'
done < <(extract_keys "$NEW")

# keys.nix のキー式ごとの値を新旧比較し、値が変わったキー式を集める
declare -A OLD_VAL NEW_VAL CHANGED_SYM
if [[ -n "$OLD_KEYS_FILE" && -f "$KEYS_NEW" ]]; then
  while IFS=$'\t' read -r s v; do
    OLD_VAL["$s"]="$v"
  done < <(extract_key_values "$OLD_KEYS_FILE")
  while IFS=$'\t' read -r s v; do
    NEW_VAL["$s"]="$v"
  done < <(extract_key_values "$KEYS_NEW")
  for s in "${!NEW_VAL[@]}"; do
    if [[ ! -v OLD_VAL[$s] ]] || [[ "${OLD_VAL[$s]}" != "${NEW_VAL[$s]}" ]]; then
      CHANGED_SYM["$s"]=1
    fi
  done
  for s in "${!OLD_VAL[@]}"; do
    [[ -v NEW_VAL[$s] ]] || CHANGED_SYM["$s"]=1
  done
fi

# キー式 (レンダラが生成するので表記は安定) をソートして比較する
normalized() { printf '%s' "$1" | sort -u; }

changed_files=()
removed_files=()
if [[ ${#FILES_ARG[@]} -gt 0 ]]; then
  changed_files=("${FILES_ARG[@]}")
  for p in "${changed_files[@]}"; do
    [[ -v NEW_KEYS[$p] ]] || fail "--files に指定されたファイルが secrets.nix にありません: $p"
  done
elif [[ "$ALL" == 1 ]]; then
  changed_files=("${!NEW_KEYS[@]}")
else
  for p in "${!NEW_KEYS[@]}"; do
    if [[ ! -v OLD_KEYS[$p] ]] || [[ "$(normalized "${OLD_KEYS[$p]}")" != "$(normalized "${NEW_KEYS[$p]}")" ]]; then
      changed_files+=("$p")
    fi
  done
  # keys.nix の値が変わったキー式を参照する秘密も対象にする
  # (secrets.nix は参照式で書かれるため値だけの変更は差分に出ない)
  if [[ -n "${CHANGED_SYM[*]:-}" ]]; then
    for p in "${!NEW_KEYS[@]}"; do
      while IFS= read -r k; do
        [[ -n "$k" ]] || continue
        if [[ -v CHANGED_SYM[$k] ]]; then
          changed_files+=("$p")
          break
        fi
      done <<<"${NEW_KEYS[$p]}"
    done
  fi
  for p in "${!OLD_KEYS[@]}"; do
    [[ -v NEW_KEYS[$p] ]] || removed_files+=("$p")
  done
fi

if [[ ${#changed_files[@]} -gt 0 ]]; then
  mapfile -t changed_files < <(printf '%s\n' "${changed_files[@]}" | sort -u)
fi
if [[ ${#removed_files[@]} -gt 0 ]]; then
  mapfile -t removed_files < <(printf '%s\n' "${removed_files[@]}" | sort -u)
fi

if [[ ${#changed_files[@]} -eq 0 ]]; then
  echo "rekey.sh: 変更された秘密はありません"
  if [[ ${#removed_files[@]} -gt 0 ]]; then
    echo "orphan (secrets.nix から削除されたが .age ファイルは残存):"
    printf '  %s\n' "${removed_files[@]}"
  fi
  exit 0
fi

if [[ ${#IDENTITIES[@]} -eq 0 ]]; then
  fail "-i で復号用の鍵を指定してください (例: -i /etc/age/key.txt)"
fi
# この ragenix は -i の繰り返しを許さないため、複数の鍵は 1 つの -i に並べる
ID_ARGS=(-i "${IDENTITIES[@]}")

# ファイルごとの一時ルールファイルを書く (キー式は新しい secrets.nix から再利用)
write_rules() {
  local embed_path="$1" rules="$2" keys_import="$3" path="$4"
  {
    echo "let keys = import \"$keys_import\"; in"
    echo "{"
    echo "  \"$embed_path\" = {"
    echo "    publicKeys = ["
    printf '      %s\n' "${NEW_KEYS[$path]%$'\n'}"
    echo "    ];"
    echo "  };"
    echo "}"
  } >"$rules" || fail "一時ルールファイルの書き込みに失敗しました: $rules"
}

rekey_one() {
  local path="$1" rules out embed
  rules="$(mktemp)" || fail "mktemp に失敗しました"
  TMP_FILES+=("$rules")
  # ragenix はルール内のパスをルールファイルの親ディレクトリ基準で解決するため、
  # 絶対パスで埋め込む (相対パスのままでは /tmp 基準に解決され存在しない扱いになる)
  if [[ "$path" == /* ]]; then
    embed="$path"
  else
    embed="$SCRIPT_DIR/$path"
  fi
  write_rules "$embed" "$rules" "$SCRIPT_DIR/keys.nix" "$path"
  out="$("${RAGENIX[@]}" -r --rules "$rules" "${ID_ARGS[@]}" 2>&1)" || {
    echo "FAILED: $path" >&2
    printf '%s\n' "$out" | sed -e 's/\x1b\[[0-9;]*m//g' -e 's/^/    /' >&2
    return 1
  }
  if printf '%s' "$out" | grep -q "Does not exist"; then
    echo "skipped (ファイル未作成。ragenix -e で作成してください): $path"
    return 0
  fi
  echo "rekeyed: $path"
}

refs_for() {
  awk -v f="$1" '
    {
      line = $0
      sub(/^[[:space:]]+/, "", line)
      if (line == "# " f) {
        getline
        sub(/^[[:space:]]*#   referenced by: /, "", $0)
        print
        exit
      }
    }
  ' "$NEW"
}

failed_files=()
RAGENIX=(ragenix)
if ! command -v ragenix >/dev/null 2>&1; then
  RAGENIX=(nix run nixpkgs#ragenix --)
fi
for p in "${changed_files[@]}"; do
  rekey_one "$p" || failed_files+=("$p")
done

if [[ -n "$FAILED_OUT" ]]; then
  if [[ ${#failed_files[@]} -gt 0 ]]; then
    printf '%s\n' "${failed_files[@]}" >"$FAILED_OUT"
  else
    : >"$FAILED_OUT"
  fi
fi

echo ""
echo "rekey.sh: ${#changed_files[@]} file(s) changed, ${#failed_files[@]} failed"
if [[ ${#removed_files[@]} -gt 0 ]]; then
  echo "orphan (secrets.nix から削除されたが .age ファイルは残存):"
  printf '  %s\n' "${removed_files[@]}"
fi
if [[ ${#failed_files[@]} -gt 0 ]]; then
  echo "error: 以下の秘密を rekey できませんでした:" >&2
  for f in "${failed_files[@]}"; do
    refs="$(refs_for "$f")"
    echo "  $f${refs:+ (参照: $refs)}" >&2
  done
  echo "  参照しているホストで rekey してください: git commit → そのホストで" >&2
  echo "  git pull して rekey.sh --files を実行 → push → ここで git pull" >&2
  exit 1
fi
