set -e

rm -r tmp
mkdir -p tmp/mnt/persist/etc/age
, rage-keygen -o tmp/mnt/persist/etc/age/key.txt
chmod 600 tmp/mnt/persist/etc/age/key.txt

# 公開鍵を抽出
PUBLIC_KEY=$(grep '# public key:' tmp/mnt/persist/etc/age/key.txt | awk '{print $4}')
echo "生成された公開鍵: $PUBLIC_KEY"

# secrets.nixに自動追加（既存のキーがあれば削除してから追加）
sed -i "/^    $1 = /d" secrets.nix
sed -i "/^  keys = {$/a\\    $1 = \"$PUBLIC_KEY\";" secrets.nix

echo "secrets.nixに公開鍵を追加しました"
sudo ragenix -r -i "${2:-/etc/age/key.txt}"
ssh nixos@installer.local "nixos-generate-config --no-filesystems --show-hardware-config" > hosts/"$1"/hardware-configuration.nix
git add hosts
, nixos-anywhere --extra-files tmp --flake .#"$1" nixos@installer.local
rm -r tmp
