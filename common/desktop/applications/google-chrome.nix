{ lib, mkForEachUsers, pkgs, ... }:
{
  options.users.users = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule ({config, ...}: {
      options.custom.desktop.apps.google-chrome = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = config.custom.desktop.type != null;
        };
      };
    }));
  };

  config = {
    home-manager.users = mkForEachUsers (user: user.custom.desktop.apps.google-chrome.enable) (user: { config, ... }: {
      home.packages = [ pkgs.google-chrome ];
      home.persistence."/persist${config.home.homeDirectory}".directories = [
        ".config/google-chrome"
      ];
    });
  };
}
