#!/usr/bin/env bash
set -e

# Usage: ./install.sh <HOSTNAME>
# Example: ./install.sh hostname

FLAKE_URI="github:thukumo/dotfiles#$1"
shift

# 1. Disko (Partitioning & Mounting)
echo "Running Disko..."
nix run github:nix-community/disko -- --mode disko --flake "$FLAKE_URI"

# 2. Generate Age Key
mkdir -p /mnt/persist/etc/age
nix shell nixpkgs#rage -c rage-keygen -o /mnt/persist/etc/age/key.txt

# 3. Clone Repository (Prepare for Pull)
# FLAKE_URI (github:user/repo#host) から Git URL と Hostname を抽出
RAW_URI="${FLAKE_URI%%#*}"
HOSTNAME="${FLAKE_URI##*#}"

# github:user/repo -> https://github.com/user/repo
if [[ "$RAW_URI" == github:* ]]; then
    GIT_URL="https://github.com/${RAW_URI#github:}"
else
    GIT_URL="$RAW_URI"
fi

DEST_DIR="/mnt/persist/home/tsukumo/dotfiles"
if [ ! -d "$DEST_DIR/.git" ]; then
    echo "Cloning config to $DEST_DIR..."
    git clone "$GIT_URL" "$DEST_DIR"
fi

# 4. Wait for Rekey & Pull
echo "Waiting for rekey..."
read -p "Rekey secrets externally, push, then press [Enter] to pull and install..."

echo "Pulling latest changes..."
pushd "$DEST_DIR" > /dev/null
git pull
echo "Gen config"
pushd "hosts/$HOSTNAME" > /dev/null
nixos-generate-config --no-filesystems
popd > /dev/null
popd > /dev/null

# 5. NixOS Install
echo "Installing NixOS..."
nixos-install --flake "${DEST_DIR}#${HOSTNAME}"
