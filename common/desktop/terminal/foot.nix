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
                    url = "https://codeberg.org/dnkl/foot/raw/commit/4fd682b4e8d985ce25d2bd599c1d855bc1489650/themes/catppuccin-latte";
                    hash = "sha256-B2DLXUxrKQUOTYb80BmgsRxBzyLLrasasBz49Mc6v1M=";
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
