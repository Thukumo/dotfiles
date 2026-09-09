{
  pkgs,
  desktopLib,
  ...
}:

{
  home-manager.users = desktopLib.mkHome (user: user.custom.desktop.locker != null) (
    user: _: {
      home.shellAliases = {
        insomnia = "touch /tmp/no-suspend";
        sleepy = "rm -f /tmp/no-suspend";
        awake = "touch /tmp/no-lock";
        asleep = "rm -f /tmp/no-lock";
      };

      services.hypridle = {
        enable = true;
        settings = {
          general = {
            lock_cmd =
              let
                locker = user.custom.desktop.locker;
              in
              "${pkgs.procps}/bin/pkill -x ${locker} 2>/dev/null; ${pkgs.${locker}}/bin/${locker}";
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
    }
  );
}
