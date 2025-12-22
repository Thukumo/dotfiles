{
  lib,
  mkForEachUsers,
  pkgs,
  ...
}:

{
  options.users.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.custom.desktop.term = {
          type = lib.mkOption {
            type = lib.types.nullOr (lib.types.enum [ "foot" ]);
            default = "foot";
          };
        };
      }
    );
  };

  config = {
    home-manager.users = mkForEachUsers (user: user.custom.desktop.term.type == "foot") (user: {
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
