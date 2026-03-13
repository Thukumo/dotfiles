{
  config,
  pkgs,
  lib,
  myLib,
  ...
}:

{
  security.pam.services.hyprlock = lib.mkIf (lib.any (u: u.desktop.hyprlock.enable) (lib.attrValues config.custom.users)) { };

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
            blur_size = 7;
          }
        ];

        input-field = [
          {
            size = "200, 50";
            outline_thickness = 3;
            dots_size = 0.33;
            dots_spacing = 0.15;
            dots_center = true;
            outer_color = "rgb(151515)";
            inner_color = "rgb(200, 200, 200)";
            font_color = "rgb(10, 10, 10)";
            fade_on_empty = true;
            placeholder_text = "<i>Input Password...</i>";
            hide_input = false;
            position = "0, -20";
            halign = "center";
            valign = "center";
          }
        ];

        label = [
          {
            text = "$TIME";
            color = "rgba(200, 200, 200, 1.0)";
            font_size = 64;
            font_family = "Noto Sans";
            position = "0, 80";
            halign = "center";
            valign = "center";
          }
        ];
      };
    };

    services.swayidle = {
      enable = true;
      timeouts = [
        {
          timeout = 300;
          command = "${pkgs.hyprlock}/bin/hyprlock";
        }
        {
          timeout = 600;
          command = "${pkgs.systemd}/bin/systemctl suspend";
        }
      ];
      events = {
        before-sleep = "${pkgs.hyprlock}/bin/hyprlock";
        lock = "${pkgs.hyprlock}/bin/hyprlock";
      };
    };
  });
}
