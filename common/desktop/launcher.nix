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
        options.custom.desktop.launcher = {
          type = lib.mkOption {
            type = lib.types.nullOr (lib.types.enum [ "fuzzel" ]);
            default = "fuzzel";
          };
        };
      }
    );
  };

  # この値に関わらずniriでfuzzel使ってる
  config = {
    home-manager.users = mkForEachUsers (user: user.custom.desktop.launcher.type == "fuzzel") (user: {
      programs.fuzzel = {
        enable = true;
        settings = {
          main = {
            terminal = "${pkgs.foot}/bin/foot";
            layer = "overlay";
          };
        };
      };
    });
  };
}
