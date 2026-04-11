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
    home.shellAliases = {
      insomnia = "touch /tmp/no-suspend";
      sleepy = "rm -f /tmp/no-suspend";
      awake = "touch /tmp/no-lock";
      asleep = "rm -f /tmp/no-lock";
    };

    programs.hyprlock = {
      enable = true;
      settings = {
        general = {
          no_fade_in = false;
          grace = 0;
          disable_loading_bar = true;
        };

        background = lib.mkForce [
          {
            path = "screenshot";
            blur_passes = 3;
            blur_size = 8;
            noise = 0.0117;
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
            on-timeout = "[ ! -f /tmp/no-lock ] && loginctl lock-session";
          }
          {
            timeout = 330; # 5.5min
            on-timeout = "[ ! -f /tmp/no-lock ] && niri msg action power-off-monitors";
          }
          {
            timeout = 600; # 10min
            on-timeout = "[ ! -f /tmp/no-suspend ] && [ ! -f /tmp/no-lock ] && systemctl suspend";
          }
        ];
      };
    };
  });
}
