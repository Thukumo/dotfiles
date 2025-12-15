{ lib, config, ... }:

{
  options.custom.desktop.term = {
    type = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "foot" ]);
      default = lib.mapNullable (_: "foot") config.custom.desktop.type;
    };
  };
  config = lib.mkMerge [
    (lib.mkIf (config.custom.desktop.term.type == "foot") {
      home-manager.users."tsukumo" =
        { pkgs, ... }:
        {
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
              };
            };
          };
        };
    })
  ];
}
