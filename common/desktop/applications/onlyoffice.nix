{
  config,
  lib,
  pkgs,
  ...
}:

# apps.onlyoffice.enable を nixpkgs PR #526315 の programs.onlyoffice モジュールに繋ぐ。
# モジュールが fonts.packages を実ファイル化して FHS env の /usr/share/fonts に
# 配置するため、OnlyOffice からシステムフォント(日本語含む)が使えるようになる。
{
  config =
    lib.mkIf (lib.any (user: user.desktop.apps.onlyoffice.enable) (lib.attrValues config.custom.users))
      {
        programs.onlyoffice.enable = true;

        # LibreOffice で作られた文書は「IPA明朝」「IPAゴシック」(旧IPAフォント名)を
        # 指定していることが多い。無いと OnlyOffice が置換して描画が崩れるため、
        # 実体のフォントを入れる。
        fonts.packages = [ pkgs.ipafont ];
      };
}
