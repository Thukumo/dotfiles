_:

{
  services.glances = {
    enable = true;
    extraArgs = [
      "--webserver"
      "--bind"
      "127.0.0.1"
      "--hide-public-info"
      "--disable-check-update"
      # プロセス一覧(コマンドライン)・接続先IP・リッスンポート・IPアドレスを隠す
      # (--disable-process は UI にしか効かず API から見えるのでプラグイン単位で無効化)
      "--disable-plugin"
      "processlist,programlist,connections,ports,ip"
    ];
  };
}
