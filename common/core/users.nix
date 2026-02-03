{
  pkgs,
  lib,
  config,
  ...
}:

{
  options.custom.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          email = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "User's email address for git configuration and other uses";
          };
          persistence = {
            directories = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Additional directories to persist for this user";
            };
            files = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Additional files to persist for this user";
            };
          };
        };
      }
    );
    default = { };
    description = "Custom per-user configuration options";
  };

  config = {
    users.mutableUsers = false;

    users.users."tsukumo" = {
      isNormalUser = true;
      hashedPasswordFile = config.age.secrets."passwd_tsukumo".path;
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
      shell = pkgs.fish;
    };

    # Custom User Configuration
    custom.users."tsukumo" = {
      email = "contact@tsukumo.f5.si";
      secrets.secretKey = "/home/tsukumo/.ssh/id_ed25519";

      persistence = {
        directories = [
          "Documents"
          "dotfiles"
          ".local/share/fish"
          ".local/state/wireplumber"
          ".ssh" # for known_hosts
        ];
      };

      desktop = {
        enable = true;
        de = "niri";
        terminal = "foot";
        launcher = "fuzzel";
        ime = "skk";
      };

      dev.podman.enable = true;
    };

    # for shell
    programs.fish.enable = true;

    security.sudo.wheelNeedsPassword = false;
  };
}
