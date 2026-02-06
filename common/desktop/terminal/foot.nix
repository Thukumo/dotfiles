{
  myLib,
  pkgs,
  ...
}:

{
  config = {
    home-manager.users =
      myLib.mkForEachUsers (user: user.custom.desktop.terminal or null == "foot")
        (user: {
          programs.foot = {
            enable = true;
            server.enable = true;
            settings = {
              main = {
                font = "Adwaita Mono Nerd Font:size=10";
                include = toString (
                  pkgs.fetchurl {
                    url = "https://codeberg.org/dnkl/foot/raw/commit/6e533231b016684a32a1975ce2e33ae3ae38b4c6/themes/catppuccin-latte";
                    hash = "sha256-kTrLlIhBLFpxHUlXHCaK2nyq/m15L1iQjNngo5gPfCE=";
                  }
                );
                dpi-aware = "yes";
              };
              mouse = {
                hide-when-typing = "yes";
              };
            };
          };
        });
  };
}
