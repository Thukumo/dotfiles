
## インストール

リポジトリ直下で作業することを想定

先に\
`flake.nix`にWi-Fiの認証情報を入力して、\
`nix build .#nixosConfigurations.installer.config.system.build.isoImage`\
でインストーラのイメージを生成しておく。

mDNS(Avahi)が動作している環境でないと、installer.localの名前解決でコケる。\
自分で接続先を指定してやることで解決可能。

`./inspect-hardware.sh (nixos@ip-addr)`

`./installer.sh <host name> (nixos@ip-addr)`

現在のところ、インストール後に一度インストール先のマシン側の`~`で、手動で`git clone <URL> dotfiles`してやる必要がある

## セットアップ

`direnv allow`

## 暗号化されたデータの追加

`EDITOR='cp /dev/stdin' ragenix -e <filename>.age`にパイプすると楽

