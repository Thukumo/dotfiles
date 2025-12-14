{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.packages = with pkgs; [
    nautilus # For GNOME portal file chooser

    xwayland-satellite
    # anyrun
  ];

  # 少なくとも今使ってるNiriのflakeだと勝手に設定されてる?
  # xdg.portal = {
  #   enable = true;
  #   extraPortals = [ pkgs.xdg-desktop-portal-wlr pkgs.xdg-desktop-portal-gtk ];
  #   config.preferred = {
  #     default = ["wlr" "gtk"];
  #   };
  # };

  imports = [
    ./home-activate-linux.nix
  ];

  programs.niri = {
    enable = true;
    package = pkgs.niri.overrideAttrs (old: {
      doCheck = false;
      checkPhase = "";
    });
    settings = {
      prefer-no-csd = true;
      hotkey-overlay.skip-at-startup = true;

      animations = {
        slowdown = 0.5;
        window-open.enable = false;
        window-close.enable = false;
        window-resize.enable = false;
      };

      gestures.hot-corners.enable = false;
      input = {
        mod-key = "Super";
        keyboard = {
          repeat-delay = 400;
          xkb.layout = "jp";
        };
        touchpad = {
          enable = false;
          # dwt = true;
          # tap = true;
        };
      };
      layout = {
        default-column-width.proportion = 0.5;
        gaps = 8;
      };
      binds =
        with config.lib.niri.actions;
        lib.mapAttrs
          (_: action: {
            inherit action;
            repeat = false;
          })
          (
            let
              normalBind = {
                "Shift+P" = power-off-monitors;

                "Return" = spawn "${pkgs.foot}/bin/footclient";
                "Space" = spawn "fuzzel";
                # "Space" = spawn "anyrun";
                "M" = spawn "chromium" "--new-window";

                "H" = focus-column-left;
                "L" = focus-column-right;
                "K" = focus-window-up;
                "J" = focus-window-down;
                "Shift+H" = move-column-left;
                "Shift+L" = move-column-right;
                "Shift+K" = move-window-up;
                "Shift+J" = move-window-down;

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
              other = {
                "XF86AudioRaiseVolume" = spawn "swayosd-client" "--output-volume" "raise";
                "XF86AudioLowerVolume" = spawn "swayosd-client" "--output-volume" "lower";
                "XF86AudioMute" = spawn "swayosd-client" "--output-volume" "mute-toggle";
                "XF86AudioMicMute" = spawn "swayosd-client" "--input-volume" "mute-toggle";
                "XF86MonBrightnessUp" = spawn "swayosd-client" "--brightness" "raise";
                "XF86MonBrightnessDown" = spawn "swayosd-client" "--brightness" "lower";
              };
            in
            (lib.mapAttrs' (key: lib.nameValuePair "Mod+${key}") (normalBind // worksp)) // other
          );
      spawn-at-startup = [
        # fcitx5は、autostartにファイルがあるから不要っぽい
        {
          argv = [
            "${pkgs.brightnessctl}/bin/brightnessctl"
            "set"
            "100%"
          ];
        }
        {
          argv = [
            "bash"
            "-c"
            "LANG=C ${pkgs.activate-linux}/bin/activate-linux -d"
          ];
        }
      ];
    };
  };

  services.batsignal = {
    enable = true;
    extraArgs = [ "-p" ];
  };
  services.swayosd.enable = true;
}
