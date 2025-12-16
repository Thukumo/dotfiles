#!/usr/bin/env bash
set -e

# Usage: ./install.sh <HOSTNAME>
# Example: ./install.sh hostname

HOSTNAME="$1"

# スクリプトがある場所のディレクトリ名を取得
SCRIPT_DIR=$(cd $(dirname $0); pwd)

# もし今いる場所が "dotfiles" という名前なら、すでに中にいると判断して何もしない
# そうでなければ dotfiles ディレクトリを探して入る
if [ "$(basename "$PWD")" != "dotfiles" ]; then
    if [ -d "dotfiles" ]; then
        cd dotfiles
    elif [ -d "$SCRIPT_DIR/dotfiles" ]; then
        cd "$SCRIPT_DIR/dotfiles"
    else
        echo "Error: 'dotfiles' directory not found."
        exit 1
    fi
fi

echo "Gen config"
pushd "hosts/$HOSTNAME"
nixos-generate-config --no-filesystems --dir .
git add hardware-configuration.nix
popd

# 1. Disko (Partitioning & Mounting)
echo "Running Disko..."
nix --extra-experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko --flake ".#$HOSTNAME"

# 2. Generate Age Key
echo "Generate age key"
mkdir -p /mnt/persist/etc/age
nix --extra-experimental-features "nix-command flakes" shell nixpkgs#rage -c rage-keygen -o /mnt/persist/etc/age/key.txt

# 3. Wait for Rekey & Pull
echo "Waiting for rekey..."
read -p "Rekey secrets externally, push, then press [Enter] to pull and install..."

# 4. Clone Repository (Prepare for Pull)

DEST_DIR="/mnt/persist/home/tsukumo/dotfiles"
git clone https://github.com/thukumo/dotfiles "$DEST_DIR"

echo "Gen config"
pushd "$DEST_DIR/hosts/$HOSTNAME"
nixos-generate-config --no-filesystems --dir .
git add hardware-configuration.nix
popd

# 5. NixOS Install
echo "Installing NixOS..."
nixos-install --flake "${DEST_DIR}#${HOSTNAME}"

