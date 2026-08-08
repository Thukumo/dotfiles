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
    "16x-aurora" = "age1rq8eqfp4qsznzau3xla2ftq26d3wlhjk05l9c4tnwcpkj7ecxfqqfvtjad";
    "backup-pixel9a" = "age1akl70p6av6sjhuqa8wrr9ms5vn0jy6kgn5vh35c9m0jmg6hlrqtq9hp4cm";
    "mouse-3" = "age17f6qmquda9s8p2vegu0ynzmnyfhgqd9gxre4kngf87wagf5nvfeqas89m5";
    "thinkpadx13-nix" = "age1y3w68vz3g24mcaqu42vg76q0p9urnjekn42p60nlxnkh2zgdwqfsm4txkl";
    "yoga-book" = "age1u7eks62u4kj6y7v4hrcfumcvcwd3hlwkrw7su6l50x6ldreqpdnqsxjr2l";
  };
  homeKeys = {
    "tsukumo" = {
      "16x-aurora" = "age1n9duyldcz8d3dgkckn3se69kxc057g0dzz5kfadgal3ensl86utqfwjngy";
      "mouse-3" = "age1kd5p06my5ynydcpwssl3l8qlf34d8zqk6ejtywzes98kcp4chv0sphk3vs";
      "thinkpadx13-nix" = "age1kc79w5k0ua9gv9efqlysx7l8ydqgf02ntmjzpgm33lh0zzenlcuqjz3837";
      "yoga-book" = "age1j2emsn9y3ey4h7ggwf0wha44elkchuswslg84vwgk7ch52kzxvesddfrge";
    };
  };
  universalRecipients = [
    "backup-pixel9a"
  ];
  extraRecipients = { };
}
