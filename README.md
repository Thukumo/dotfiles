
## インストール

リポジトリ直下で作業することを想定

先に\
`flake.nix`にWi-Fiの認証情報を入力して、\
`nix build .#nixosConfigurations.installer.config.system.build.isoImage`\
でインストーラのイメージを生成しておく。

mDNS(Avahi)が動作している環境でないと、installer.localの名前解決でコケる。\
自分で接続先を指定してやることで解決可能。

`./inspect-hardware.sh (nixos@ip-addr)`

`./installer.sh [--remote] <host name> (nixos@ip-addr)`

`--remote`オプションを付けると、ターゲットマシン上でビルドを実行する。

現在のところ、インストール後に一度インストール先のマシン側の`~`で、手動で`git clone <URL> dotfiles`してやる必要がある

## セットアップ

`direnv allow`

## ragenix

### データの追加

`EDITOR='cp /dev/stdin' ragenix -e <filename>.age`にパイプすると楽

### 編集

```sh
# システムのsecret編集
sudo ragenix -e <file>.age -i /etc/age/key.txt
# ユーザーのsecret編集 (keyは<home>/.config/age/home-manager_key)
ragenix -e <file>.age -i ~/.config/age/home-manager_key
```

ホストを増やす/秘密の参照を変えた場合は、`ragenix -r` で rekey が必要:

```sh
sudo ragenix -r -i /etc/age/key.txt -i ~/.config/age/home-manager_key
```

`installer.sh` は新ホストのシステムキー・ホームキーを生成し、`keys.nix` への登録・`secrets.nix` の再生成・rekey まで自動で行う。

## WinApps

`podman-compose --file .config/winapps/compose.yaml up -d`
初回 or アプリの入れ消しの度に
`winapps-setup --user --setupAllOfficiallySupportedApps`

## 顔認証 (Gaze)

```sh
gaze add-face default   # 顔を登録
gaze auth --verbose     # 動作確認
```

