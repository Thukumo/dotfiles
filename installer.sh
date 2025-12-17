#!/usr/bin/env bash
set -e

# Usage: ./install.sh <HOSTNAME>
# Example: ./install.sh hostname

HOSTNAME="$1"

# スクリプトがある場所のディレクトリを取得して、そこに移動する
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$SCRIPT_DIR"

echo "Gen config"
pushd "hosts/$HOSTNAME"
nixos-generate-config --no-filesystems --dir .
git add hardware-configuration.nix
popd

# 1. Disko (Partitioning & Mounting)
echo "Running Disko..."
sudo nix --extra-experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko --flake ".#$HOSTNAME"

# 2. Generate Age Key
echo "Generate age key"
sudo mkdir -p /mnt/persist/etc/age
sudo nix --extra-experimental-features "nix-command flakes" shell nixpkgs#rage -c rage-keygen -o /mnt/persist/etc/age/key.txt

# 3. Wait for Rekey & Pull
echo "Waiting for rekey..."
read -p "Rekey secrets externally, push, then press [Enter] to pull and install..."

# 4. Clone Repository (Prepare for Pull)

DEST_DIR="/mnt/persist/home/tsukumo/dotfiles"
sudo git clone https://github.com/thukumo/dotfiles "$DEST_DIR"
sudo chown -R tsukumo /mnt/persist/home/tsukumo

echo "Gen config"
pushd "$DEST_DIR/hosts/$HOSTNAME"
nixos-generate-config --no-filesystems --dir .
git add hardware-configuration.nix
popd

# 5. NixOS Install
echo "Installing NixOS..."
nixos-install --flake "${DEST_DIR}#${HOSTNAME}"

