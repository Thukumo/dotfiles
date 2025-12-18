set -e

mkdir -p tmp/mnt/persist/etc/age
, rage-keygen -o tmp/mnt/persist/etc/age/key.txt
chmod 600 tmp/mnt/persist/etc/age/key.txt
read -p '公開鍵追加後にエンターキーを押下'
sudo ragenix -r -i "${2:-/etc/age/key.txt}"
ssh nixos@installer.local "nixos-generate-config --no-filesystems --show-hardware-config" > hosts/"$1"/hardware-configuration.nix
git add hosts
, nixos-anywhere --extra-files tmp --flake .#"$1" nixos@installer.local
rm -r tmp
