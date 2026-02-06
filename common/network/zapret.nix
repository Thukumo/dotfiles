_:

{
  services.zapret = {
    enable = false;
    # params は nfqws への直接の引数リストです
    params = [
      # --- プロフィール 1: HTTP (Port 80) 対策 ---
      "--filter-tcp=80"
      "--methodeol" # メソッドの前に改行を挿入
      "--dpi-desync=multisplit"
      "--dpi-desync-split-pos=method+2" # HTTPメソッドの直後で分割

      "--new" # 次のプロフィールへ

      # --- プロフィール 2: HTTPS (Port 443) 対策 ---
      "--filter-tcp=443"
      "--dpi-desync=fake,multidisorder" # パケット順序を入れ替えて混乱させる
      "--dpi-desync-split-pos=1,midsld" # ドメイン名の途中で分割
      "--dpi-desync-fooling=badseq" # 偽パケットを無視させるための細工
    ];
  };
}
