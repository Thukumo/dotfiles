{ pkgs, ... }:

{
  home.packages = with pkgs; [
    xfce.thunar
  ];

  imports = [
  ];
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
        include = toString (
          pkgs.fetchurl {
            url = "https://codeberg.org/dnkl/foot/raw/commit/6e533231b016684a32a1975ce2e33ae3ae38b4c6/themes/catppuccin-latte";
            hash = "sha256-kTrLlIhBLFpxHUlXHCaK2nyq/m15L1iQjNngo5gPfCE=";
          }
        );
      };
      mouse = {
        hide-when-typing = true;
        # hide-when-typing = "yes";
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
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
  };
}
