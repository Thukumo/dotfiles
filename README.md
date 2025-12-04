## install

略\
`mkdir -p /mnt/persist/etc/age`\
`sudo nix shell nixpkgs#age -c age-keygen -o /mnt/persist/etc/age/key.txt`

## 暗号化されたデータの追加

`EDITOR='cp /dev/stdin' ragenix -e <filename>.age`にパイプすると楽

