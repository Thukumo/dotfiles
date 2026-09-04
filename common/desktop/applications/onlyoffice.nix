{
  config,
  lib,
  myLib,
  pkgs,
  ...
}:

# apps.onlyoffice.enable を nixpkgs PR #526315 の programs.onlyoffice モジュールに繋ぐ。
# extraFontPackages に文書用のフォントだけを渡す。空のままだと fonts.packages
# 全量が実ファイル化され、ターミナル用・絵文字までピッカーに混ざって肥大化する。
# noto-cjk-sans はパッケージ側で同梱済みのため指定不要。
{
  config = lib.mkIf (myLib.anyUser config (user: user.desktop.apps.onlyoffice.enable)) {
    programs.onlyoffice = {
      enable = true;

      # LibreOffice で作られた文書は「IPA明朝」「IPAゴシック」(旧IPAフォント名)を
      # 指定していることが多い。無いと OnlyOffice が置換して描画が崩れるため、
      # 実体のフォントを入れる。
      extraFontPackages = with pkgs; [
        ipafont
        ipaexfont
        liberation_ttf
        dejavu_fonts
        noto-fonts-cjk-serif
      ];
    };
  };
}
