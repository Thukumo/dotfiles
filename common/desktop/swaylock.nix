{
  config,
  pkgs,
  lib,
  myLib,
  ...
}:

{
  security.pam.services.swaylock = lib.mkIf (lib.any (u: u.desktop.swaylock.enable) (lib.attrValues config.custom.users)) { };

  home-manager.users = myLib.mkForEachUsers (user: user.custom.desktop.swaylock.enable) (_: {
    programs.swaylock = {
      enable = true;
      package = pkgs.swaylock-effects;
      settings = {
        screenshots = true;
        clock = true;
        indicator = true;
        indicator-radius = 100;
        indicator-thickness = 10;

        # エフェクト: 強めのブラー + グレイスケール + 周辺減光
        effect-blur = "20x15";
        effect-greyscale = true;
        effect-vignette = "0.5:0.5";

        # フォント設定
        font = "sans-serif";
        datestr = "%Y年%m月%d日";
        timestr = "%H:%M";

        # 配色設定 (鮮やかなグラデーション風)
        ring-color = "8833ff";        # 通常時のリング (紫)
        inside-color = "00000000";    # リングの内側 (透明)
        key-hl-color = "ff00cc";      # 入力時のハイライト (ピンク)
        separator-color = "00000000"; # セパレーター (透明)

        # 状態別カラー
        ring-ver-color = "00ffcc";    # 検証中 (ターコイズ)
        inside-ver-color = "00000000";
        ring-wrong-color = "ff3333";  # 失敗時 (赤)
        inside-wrong-color = "00000000";
        ring-clear-color = "ffffff";  # クリア時 (白)
        inside-clear-color = "00000000";

        # テキストカラー
        text-color = "ffffff";
        text-ver-color = "ffffff";
        text-wrong-color = "ffffff";
        text-clear-color = "ffffff";

        line-use-inside = true;
        show-failed-attempts = true;
      };
    };

    services.swayidle = {
      enable = true;
      timeouts = [
        {
          timeout = 300;
          command = "${pkgs.swaylock-effects}/bin/swaylock -f";
        }
        {
          timeout = 600;
          command = "${pkgs.systemd}/bin/systemctl suspend";
        }
      ];
      events = {
        before-sleep = "${pkgs.swaylock-effects}/bin/swaylock -f";
        lock = "${pkgs.swaylock-effects}/bin/swaylock -f";
      };
    };
  });
}
