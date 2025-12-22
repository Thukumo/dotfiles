{
  lib,
  config,
  mkForEachUsers,
  pkgs,
  ...
}:

{
  options.users.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.custom.desktop.ime = {
          type = lib.mkOption {
            type = lib.types.nullOr (lib.types.enum [ "skk" ]);
            default = null;
          };
        };
      }
    );
  };

  config = {
    home-manager.users = mkForEachUsers (user: user.custom.desktop.ime.type == "skk") (user: {
      i18n.inputMethod = {
        enable = true;
        type = "fcitx5";
        fcitx5 = {
          addons = with pkgs; [
            fcitx5-skk
            fcitx5-gtk
          ];
        };
      };
    });
  };
}
