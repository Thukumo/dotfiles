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
          # NixOS user account (users.users.<name>) settings derived from custom.users.
          account.userConfig = lib.mkOption {
            type = lib.types.attrs;
            default = { };
            description = "Attribute set merged into users.users.<name>.";
          };

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

    assertions =
      let
        normalUsers = lib.filterAttrs (_: u: u.isNormalUser or false) config.users.users;
        normalNames = lib.attrNames normalUsers;
        customNames = lib.attrNames config.custom.users;

        missingInCustom = lib.filter (n: !(builtins.hasAttr n config.custom.users)) normalNames;
        missingInUsers = lib.filter (n: !(builtins.hasAttr n config.users.users)) customNames;
        customNotNormal = lib.filter (
          n: (builtins.hasAttr n config.users.users) && !((config.users.users.${n}.isNormalUser or false))
        ) customNames;
      in
      [
        {
          assertion = missingInCustom == [ ];
          message = "Every normal user must be defined in custom.users (single source of truth). Missing: ${lib.concatStringsSep ", " missingInCustom}";
        }
        {
          assertion = missingInUsers == [ ];
          message = "custom.users.<name> is defined but users.users.<name> does not exist (module ordering/typo?): ${lib.concatStringsSep ", " missingInUsers}";
        }
        {
          assertion = customNotNormal == [ ];
          message = "custom.users must map to normal users (users.users.<name>.isNormalUser = true). Offenders: ${lib.concatStringsSep ", " customNotNormal}";
        }
      ];

    users.users = lib.mkMerge (
      lib.mapAttrsToList (name: userCfg: {
        ${name} = {
          isNormalUser = lib.mkDefault true;
        }
        // userCfg.account.userConfig;
      }) config.custom.users
    );

    # NOTE: Avoid deriving `custom.users` from `config.users.users`.
    # Doing so can create an evaluation cycle when other modules (e.g. VR/wivrn)
    # enable services based on `config.custom.users`, and those services in turn
    # affect `users.users` via upstream NixOS modules.
    custom.users = {
      "tsukumo" = {
        account.userConfig = {
          hashedPasswordFile = config.age.secrets."passwd_tsukumo".path;
          extraGroups = [
            "networkmanager"
            "wheel"
          ];
          shell = pkgs.fish;
        };

        email = "contact@tsukumo.f5.si";
        secrets.secretKey = "/home/tsukumo/.ssh/id_ed25519";

        persistence = {
          directories = [
            "Documents"
            "dotfiles"
            ".local/share/fish"
            ".local/state/wireplumber"
          ];
          files = [
            ".ssh/known_hosts"
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
    };

    # for shell
    programs.fish.enable = true;

    security.sudo.wheelNeedsPassword = false;
  };
}
