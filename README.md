
## インストール

リポジトリ直下で作業することを想定

先に\
`flake.nix`にWi-Fiの接続情報を入力して、\
`nix build .#nixosConfigurations.installer.config.system.build.isoImage`\
でインストーラのイメージを生成しておく。

`bash installer.sh`

## 暗号化されたデータの追加

`EDITOR='cp /dev/stdin' ragenix -e <filename>.age`にパイプすると楽

