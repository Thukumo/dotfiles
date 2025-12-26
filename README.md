
## インストール

リポジトリ直下で作業することを想定

先に\
`flake.nix`にWi-Fiの認証情報を入力して、\
`nix build .#nixosConfigurations.installer.config.system.build.isoImage`\
でインストーラのイメージを生成しておく。

`bash installer.sh`

現在のところ、インストール後に一度インストール先のマシン側の`~`で、手動で`git clone <URL> dotfiles`してやる必要がある

## 暗号化されたデータの追加

`EDITOR='cp /dev/stdin' ragenix -e <filename>.age`にパイプすると楽

