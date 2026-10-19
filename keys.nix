# 公開鍵の単一ソース (手書きで管理する唯一のファイル)
#
# - systemKeys: ホストごとのシステム age キー (NixOS レイヤの秘密を開錠)
# - homeKeys:   ユーザー・ホストごとの home-manager age キー (ユーザーレイヤの秘密を開錠)
# - universalRecipients: systemKeys の名前。災害復旧用など、全ての秘密の
#   recipient に常に含めるキー (例: backup-pixel9a)
# - extraRecipients: 生成ルールに含まれない秘密への手動 recipient 追加
#
# secrets.nix はこのファイルと各ホストの age.secrets 宣言から自動生成される
# (git commit 時に自動再生成)。
{
  systemKeys = {
    "yoga-book" = "age1fztfqgpdc7q5z05t9zcff7skpv0xeq2a6j398yvs58qdns872faszlxyd2";
    "16x-aurora" = "age1rq8eqfp4qsznzau3xla2ftq26d3wlhjk05l9c4tnwcpkj7ecxfqqfvtjad";
    "backup-pixel9a" = "age1akl70p6av6sjhuqa8wrr9ms5vn0jy6kgn5vh35c9m0jmg6hlrqtq9hp4cm";
    "mouse-3" = "age18wlnmdffy82jjqm0cyk42e8y29d777ccc55rv4fp7jdjlg6jcqxsqmnm4g";
    "thinkpadx13-nix" = "age1y3w68vz3g24mcaqu42vg76q0p9urnjekn42p60nlxnkh2zgdwqfsm4txkl";
  };
  homeKeys = {
    "tsukumo" = {
      "yoga-book" = "age1jlktepf3wz3nre58pu2a6qdeesmnmzw6wtw3t4uz4xysf076v3xsxgx6k6";
      "16x-aurora" = "age1n9duyldcz8d3dgkckn3se69kxc057g0dzz5kfadgal3ensl86utqfwjngy";
      "mouse-3" = "age13jy3je2yy9ucymyar32m8rp2upu6qh235wq42nr3pgsprrq22y7szts2n0";
      "thinkpadx13-nix" = "age1yqrh69757nsk8vtjq8dlu3738f7pgcq0v6cdulgd2uptgttdqqlsgg8tge";
    };
  };
  universalRecipients = [
    "backup-pixel9a"
  ];
  extraRecipients = { };
}
