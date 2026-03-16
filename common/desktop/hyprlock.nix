{
  config,
  pkgs,
  lib,
  myLib,
  ...
}:

{
  security.pam.services.hyprlock = lib.mkIf (lib.any (u: u.desktop.hyprlock.enable) (
    lib.attrValues config.custom.users
  )) { };

  home-manager.users = myLib.mkForEachUsers (user: user.custom.desktop.hyprlock.enable) (_: {
    programs.hyprlock = {
      enable = true;
      settings = {
        general = {
          no_fade_in = false;
          grace = 0;
          disable_loading_bar = true;
        };

        background = [
          {
            path = "screenshot";
            blur_passes = 3;
            blur_size = 8;
            noise = 0.0117;
          }
        ];

        input-field = [
          {
            size = "250, 50";
            outline_thickness = 2;
            dots_size = 0.2;
            dots_spacing = 0.2;
            dots_center = true;
            outer_color = "rgba(255, 255, 255, 0.1)";
            inner_color = "rgba(255, 255, 255, 0.1)";
            font_color = "rgb(200, 200, 200)";
            fade_on_empty = false;
            placeholder_text = "<i>Password...</i>";
            hide_input = false;
            position = "0, -50";
            halign = "center";
            valign = "center";
            shadow_passes = 2;
          }
        ];

        label = [
          # 時刻表示
          {
            text = "$TIME";
            color = "rgba(255, 255, 255, 0.9)";
            font_size = 120;
            font_family = "sans-serif";
            position = "0, 150";
            halign = "center";
            valign = "center";
            shadow_passes = 3;
            shadow_size = 4;
          }
          # 日付・曜日表示
          {
            text = "cmd[update:18000000] echo \"<b>$(LC_TIME=C date +'%A, %B %d')</b>\"";
            color = "rgba(255, 255, 255, 0.9)";
            font_size = 24;
            font_family = "sans-serif";
            position = "0, 50";
            halign = "center";
            valign = "center";
            shadow_passes = 2;
          }
          # ユーザーへの挨拶
          {
            text = "Hi there, $USER";
            color = "rgba(255, 255, 255, 0.7)";
            font_size = 16;
            font_family = "sans-serif";
            position = "0, -120";
            halign = "center";
            valign = "center";
          }
        ];
      };
    };

    services.hypridle = {
      enable = true;
      settings = {
        general = {
          lock_cmd = "pidof hyprlock || ${pkgs.hyprlock}/bin/hyprlock";
          before_sleep_cmd = "loginctl lock-session";
        };

        listener = [
          {
            timeout = 300; # 5min
            on-timeout = "loginctl lock-session";
          }
          {
            timeout = 330; # 5.5min
            on-timeout = "niri msg action power-off-monitors";
          }
          {
            timeout = 600; # 10min
            on-timeout = "systemctl suspend";
          }
        ];
      };
    };
  });
}
