{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    xfce.thunar

    # for niri
    xwayland-satellite
    anyrun
    slurp
    grim
    wl-clipboard
    
    acpi
    libnotify
    brightnessctl
  ];

  imports = [
    ./desktop_app.nix
    # ./steam.nix
  ];

  # 少なくとも今使ってるNiriのflakeだと勝手に設定されてる?
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-wlr pkgs.xdg-desktop-portal-gtk ];
    config.preferred = {
      default = ["wlr" "gtk"];
    };  
  };
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
      binds = with config.lib.niri.actions; lib.mapAttrs (_: action: { inherit action; repeat = false; }) (
        let
          normalBind = {
            "Shift+E" = quit;
            "Shift+P" = power-off-monitors;

            "Return" = spawn "footclient";
            "Space" = spawn "fuzzel";
            # "Space" = spawn "anyrun";
            "M" = spawn "mattermost-desktop";

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

            "P" = spawn "sh" "-c" "slurp | grim -g - - | wl-copy";

            "A" = spawn "sh" "-c" "notify-send \"$(date +%H:%M:%S)\" \"$(date +%Y/%m/%d)\n$(acpi -b | cut -d: -f2- | sed 's/^, //')\"";
          };
          worksp = builtins.listToAttrs (map (n: {
            name = toString n;
            value = focus-workspace n;
          }) (lib.range 0 9));
          other = {
            "XF86AudioRaiseVolume" = spawn "swayosd-client" "--output-volume" "raise";
            "XF86AudioLowerVolume" = spawn "swayosd-client" "--output-volume" "lower";
            "XF86AudioMute" = spawn "swayosd-client" "--output-volume" "mute-toggle";
            "XF86AudioMicMute" = spawn "swayosd-client" "--input-volume" "mute-toggle";
            "XF86MonBrightnessUp" = spawn "swayosd-client" "--brightness" "raise";
            "XF86MonBrightnessDown" = spawn "swayosd-client" "--brightness" "lower";
          };
        in (lib.mapAttrs' (key: lib.nameValuePair "Mod+${key}") (normalBind // worksp)) // other
      );
      spawn-at-startup = [
        # fcitx5は、autostartにファイルがあるから不要っぽい
        { argv = [ "brightnessctl" "set" "100%" ]; }
      ];
    };
  };
  wayland.windowManager.sway = {
    enable = true;
    config = rec {
      modifier = "Mod4";
      terminal = "foot";
      input = {
        "type:keyboard" = { "xkb_layout" = "jp"; };
      };
      startup = [
        { command = "fcitx5 -rd"; }
      ];
      keybindings = lib.mkOptionDefault (lib.attrsets.mapAttrs' (
        name: lib.nameValuePair "${modifier}+${name}"
      ) {
          "space" = "exec fuzzel";
          "q" = "kill";
          "Shift+e" = "exec swaymsg exit";
          "m" = "exec mattermost-desktop";
        });
    };
    wrapperFeatures.gtk = true;
  };
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        use-bold = "yes";
        dpi-aware = "no";
        font = "Adwaita Mono Nerd Font:size=18";
      };
    };
  };
  programs.foot = {
    enable = true;
    server.enable = true;
    settings = {
      main = {
        font = "Adwaita Mono Nerd Font:size=12";
        # include = "${pkgs.fetchurl {
        #   url = "https://raw.githubusercontent.com/catppuccin/foot/8d263e0e6b58a6b9ea507f71e4dbf6870aaf8507/themes/catppuccin-latte.ini";
        #   hash = "sha256-aAosa4MTxbYiqbNbcqLHIAwLfrsGsny4/VnObh47qOE=";
        # }}";
      };
      mouse = {
        hide-when-typing = true;
      };
    };
  };
  services.mako = {
    enable = true;
    settings = {
      ignore-timeout = 1;
      default-timeout = 5000;
      max-visible = 10;
    };
  };
  services.batsignal = {
    enable = true;
    extraArgs = [ "-p" ];
  };
  services.swayosd.enable = true;
  home.sessionVariables = {
    # GTK_IM_MODULE = "fcitx";
    # QT_IM_MODULE = "fcitx";
    # GTK_IM_MODULE = "wayland";
    # QT_IM_MODULE = "wayland";
    # # XMODIFIERS = lib.mkForce "@im=fcitx";
    # Waylandネイティブアプリ用の設定
    # INPUT_METHOD = "fcitx";
    # # SDL_IM_MODULE = lib.mkForce "fcitx";

    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
  };
}

