
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

## シークレット管理 (ragenix / age)

### 秘密ファイルの作成・編集

```sh
# 新規作成（標準入力から流し込む場合）
echo -n "secret-content" | EDITOR='cp /dev/stdin' ragenix -e <file>.age

# 編集（システム）
sudo ragenix -e <file>.age -i /etc/age/key.txt

# 編集（ユーザー）
ragenix -e <file>.age -i ~/.config/age/home-manager_key
```

### 再暗号化 (rekey.sh)

ホストの追加や秘密の参照設定を変更した際、受信者（公開鍵）を更新するために実行します。  
`rekey.sh` は `git HEAD:secrets.nix` との差分を検出し、**受取人が変更されたファイルのみを個別**に再暗号化します（手元の鍵で復号できない他ホスト専用の秘密があっても処理を中断しません）。

```sh
# システムの秘密を含む場合
sudo ./rekey.sh -i /etc/age/key.txt -i ~/.config/age/home-manager_key

# ユーザーの秘密のみの場合
./rekey.sh -i ~/.config/age/home-manager_key
```

#### 他ホスト専用の秘密が含まれる場合
手元の鍵で復号できない秘密がある場合、エラーとともに対象ファイルおよび参照ホスト名が表示されます。以下の手順で該当ホストから再暗号化してください。

1. **作業マシン**: 変更をコミットしてプッシュ
   ```sh
   git add -A
   git commit --no-verify -m "rekey: update keys"
   git push
   ```
2. **参照ホスト**: pull して該当ファイルのみ rekey し、プッシュ
   ```sh
   git pull
   sudo ./rekey.sh --files <対象ファイル> -i /etc/age/key.txt -i ~/.config/age/home-manager_key
   git add <対象ファイル>
   git commit --no-verify -m rekey
   git push
   ```
   > **Note**: 競合を防ぐため、参照ホストでは必ず `--files <対象ファイル>` で指定したファイルのみを rekey してください。

3. **作業マシン**: pull して完了
   ```sh
   git pull
   ```

※ `installer.sh` 実行中に手元で復号できない秘密があった場合も、自動で上記手順が案内されて一時停止します。参照ホストでの作業完了後に Enter を押すと、新ホストの鍵による復号テストを経てインストールが自動再開されます。

#### 主なオプション・備考
- `--all`: 差分検知を無視し、全秘密を強制的に再暗号化します（鍵の入れ替え時など）。
- `--files <path>...`: 指定したファイルのみを再暗号化します。
- **新規シークレットの作成**: まだ `.age` ファイルが存在しない秘密は、事前に `ragenix -e` で作成しておいてください（未作成のままでは rekey がスキップされ、新ホストのビルドに失敗します）。
- **`installer.sh` との連携**: `installer.sh` は新ホストのシステム・ホーム鍵の生成から `keys.nix` 登録、`secrets.nix` 再生成、rekey までを自動で実行します。

## WinApps

`podman-compose --file .config/winapps/compose.yaml up -d`
初回 or アプリの入れ消しの度に
`winapps-setup --user --setupAllOfficiallySupportedApps`

## 顔認証 (Gaze)

```sh
gaze add-face default   # 顔を登録
gaze auth --verbose     # 動作確認
```

