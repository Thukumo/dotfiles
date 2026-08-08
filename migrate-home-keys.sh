#!/usr/bin/env bash
set -euo pipefail
# 移行用: 事前生成済みのホームキー (/tmp/migration-home-keys/) を各ホストに配置する。
# 使い方: ./migrate-home-keys.sh <host>...   (無指定なら全ホスト)
# 16x-aurora はローカル、それ以外は ssh 経由で配置する。

HOSTS=("$@")
if [[ ${#HOSTS[@]} -eq 0 ]]; then
  HOSTS=(16x-aurora mouse-3 thinkpadx13-nix yoga-book)
fi

for h in "${HOSTS[@]}"; do
  key="/tmp/migration-home-keys/$h"
  if [[ ! -f "$key" ]]; then
    echo "skip $h: $key が無い" >&2
    continue
  fi

  user=$(nix eval --raw --apply 'users: builtins.attrNames users' ".#nixosConfigurations.${h}.config.home-manager.users" | awk '{print $1}')
  dest="/persist/home/$user/.config/age/home-manager_key"

  if [[ "$h" == "$(hostname)" ]]; then
    echo "installing $h (local): $dest"
    sudo mkdir -p "$(dirname "$dest")"
    sudo install -m 600 -o "$user" -g users "$key" "$dest"
  else
    echo "installing $h (ssh): $dest"
    scp -q "$key" "$h":/tmp/home-manager_key
    ssh "$h" "sudo mkdir -p \"$(dirname "$dest")\" && sudo install -m 600 -o $user -g users /tmp/home-manager_key \"$dest\" && rm /tmp/home-manager_key"
  fi
done

echo "done"
