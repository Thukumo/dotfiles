{
  config,
  pkgs,
  lib,
  desktopLib,
  myConfig,
  ...
}:
{
  programs.niri.settings.binds =
    with config.lib.niri.actions;
    lib.mapAttrs
      (_: action: {
        inherit action;
        repeat = false;
      })
      (
        let
          # `desktop.browser` が未設定ならブラウザ系のキーバインドは作らない。
          browserBinds =
            let
              browser = myConfig.desktop.browser;
            in
            if browser == null then
              { }
            else
              let
                b = desktopLib.browserInfo browser;
              in
              {
                "C" = spawn b.command b.newWindow;
                "Shift+C" = spawn b.command b.privateWindow;
                "X" = spawn b.command b.newWindow "https://x.com/home";
              };

          normalBind = {
            "Shift+P" = power-off-monitors;
            "Escape" = spawn "${pkgs.hyprlock}/bin/hyprlock";

            "Return" = spawn (desktopLib.terminalInfo myConfig.desktop.terminal).command;
            "Space" = spawn (desktopLib.launcherInfo myConfig.desktop.launcher).command;
            # "Space" = spawn "anyrun";
            "M" = spawn "mattermost-desktop";

            "H" = focus-column-left;
            "L" = focus-column-right;
            "K" = focus-window-up;
            "J" = focus-window-down;
            "Shift+H" = move-column-left;
            "Shift+L" = move-column-right;
            "Shift+K" = move-column-to-workspace-up;
            "Shift+J" = move-column-to-workspace-down;

            "Q" = close-window;
            "F" = maximize-column;
            "Shift+F" = fullscreen-window;
            "O" = toggle-overview;

            "P" =
              spawn "sh" "-c"
                "${pkgs.slurp}/bin/slurp | ${pkgs.grim}/bin/grim -g - - | ${pkgs.wl-clipboard}/bin/wl-copy";

            "A" =
              spawn "sh" "-c"
                "${pkgs.libnotify}/bin/notify-send \"$(date +%H:%M:%S)\" \"$(date +%Y/%m/%d)\n$(${pkgs.acpi}/bin/acpi -b | cut -d: -f2- | sed 's/^, //')\"";
          };
          worksp = builtins.listToAttrs (
            map (n: {
              name = toString n;
              value = focus-workspace n;
            }) (lib.range 0 9)
          );
          moveW = {
            "Shift+W" = move-column-to-monitor-up;
            "Shift+A" = move-column-to-monitor-left;
            "Shift+S" = move-column-to-monitor-down;
            "Shift+D" = move-column-to-monitor-right;
          };
          other = {
            "XF86AudioRaiseVolume" = spawn "swayosd-client" "--output-volume" "raise";
            "XF86AudioLowerVolume" = spawn "swayosd-client" "--output-volume" "lower";
            "XF86AudioMute" = spawn "swayosd-client" "--output-volume" "mute-toggle";
            "XF86AudioMicMute" = spawn "swayosd-client" "--input-volume" "mute-toggle";
            "XF86MonBrightnessUp" = spawn "swayosd-client" "--brightness" "raise";
            "XF86MonBrightnessDown" = spawn "swayosd-client" "--brightness" "lower";
          };
        in
        (lib.mapAttrs' (key: lib.nameValuePair "Mod+${key}") (
          browserBinds // normalBind // worksp // moveW
        ))
        // other
      );
}
