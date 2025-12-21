{ lib, config, mkForEachUsers, pkgs, ... }:

{
  options.users.users = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options.custom.desktop.term = {
        type = lib.mkOption {
          type = lib.types.nullOr (lib.types.enum [ "foot" ]);
          default = "foot";
        };
      };
    });
  };

  config = {
    home-manager.users = mkForEachUsers (user: user.custom.desktop.term.type == "foot") (user: {
      programs.foot = {
        enable = true;
        server.enable = true;
        settings = {
          main = {
            term = "xterm-256color";
            font = "Cica:size=11";
            dpi-aware = "yes";
          };
          mouse = {
            hide-when-typing = "yes";
          };
          "key-bindings" = {
            show-urls-launch = "Control+Shift+u";
          };
        };
      };
    });
  };
}
