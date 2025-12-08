{ pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    xfce.thunar
  ];

  imports = [
    ./desktop_app.nix
    # ./steam.nix
    ./activate-linux.nix
    ./niri.nix
  ];

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

