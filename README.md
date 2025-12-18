
## インストール

リポジトリ直下で作業することを想定

先に\
`flake.nix`にWi-Fiの接続情報を入力して、\
`nix build .#nixosConfigurations.installer.config.system.build.isoImage`\
でインストーラのイメージを生成しておく。

`mkdir -p tmp/mnt/persist/etc/age`\
`, rage-keygen -o tmp/mnt/persist/etc/age/key.txt`\
`chmod 600 tmp/mnt/persist/etc/age/key.txt`
(公開鍵をsecrets.nixに登録)\
`rekey`\
`ssh nixos@installer.local "nixos-generate-config --no-filesystems --show-hardware-config" > hosts/<構成名>/hardware-configuration.nix`\
`git add hosts`\
`, nixos-anywhere -- --extra-files tmp --flake .#<構成名> nixos@installer.local`\
`rm -r tmp && rm result`

## 暗号化されたデータの追加

`EDITOR='cp /dev/stdin' ragenix -e <filename>.age`にパイプすると楽

