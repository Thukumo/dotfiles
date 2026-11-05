{
  pkgs,
  lib,
  config,
  myLib,
  ...
}:
let
  user = import ../../../const/user.nix;
in
{
  options.custom.users =
    myLib.mkUserOption {
      options = {
        # NixOS user account (users.users.<name>) settings derived from custom.users.
        account = {
          userConfig = lib.mkOption {
            type = lib.types.attrs;
            default = { };
            description = "Attribute set merged into users.users.<name>.";
          };
          # shell.private.enableとの衝突を回避している
          shell = lib.mkOption {
            type = lib.types.nullOr (
              lib.types.enum [
                "nushell"
                "zsh"
                "fish"
              ]
            );
            default = null;
            description = "Login shell for this user";
          };
        };

        email = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "User's email address for git configuration and other uses";
        };
        dotfilesPath = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Path to dotfiles directory (relative to home). Enables NixOS management aliases when set.";
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
    // {
      default = { };
      description = "Custom per-user configuration options";
    };

  options.custom.defaultUser = lib.mkOption {
    type = lib.types.str;
    default = user.name;
    description = "Default user for desktop sessions and host-level user services";
  };

  config = {
    users.mutableUsers = false;

    assertions =
      let
        normalUsers = lib.filterAttrs (_: u: u.isNormalUser) config.users.users;
        normalNames = lib.attrNames normalUsers;
        customNames = lib.attrNames config.custom.users;

        missingInCustom = lib.filter (n: !(builtins.hasAttr n config.custom.users)) normalNames;
        missingInUsers = lib.filter (n: !(builtins.hasAttr n config.users.users)) customNames;
        customNotNormal = lib.filter (
          n: (builtins.hasAttr n config.users.users) && !config.users.users.${n}.isNormalUser
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
        {
          assertion = builtins.hasAttr config.custom.defaultUser config.custom.users;
          message = "custom.defaultUser '${config.custom.defaultUser}' must be present in custom.users.";
        }
      ];

    users.users = lib.mkMerge (
      lib.mapAttrsToList (name: userCfg: {
        ${name} = {
          isNormalUser = lib.mkDefault true;
        }
        // userCfg.account.userConfig
        // lib.optionalAttrs (userCfg.account.shell != null) {
          shell = pkgs.${userCfg.account.shell};
        };
      }) config.custom.users
    );

    # NOTE: Avoid deriving `custom.users` from `config.users.users`.
    # Doing so can create an evaluation cycle when other modules (e.g. VR/wivrn)
    # enable services based on `config.custom.users`, and those services in turn
    # affect `users.users` via upstream NixOS modules.
    custom.users = {
      "${user.name}" = {
        account = {
          userConfig = {
            hashedPasswordFile = config.age.secrets."passwd_tsukumo".path;
            extraGroups = [
              "wheel"
            ];
            openssh.authorizedKeys.keyFiles = [
              ../../shell/ssh/id_ed25519.pub
            ];
          };
          shell = "nushell";
        };

        inherit (user) email dotfilesPath;

        persistence = {
          directories = [
            "Documents"
            ".local/state/wireplumber"
          ];
          files = [
            ".ssh/known_hosts"
          ];
        };

        desktop = {
          enable = lib.mkDefault true;
          de = lib.mkDefault "niri";
          terminal = lib.mkDefault "foot";
          launcher = lib.mkDefault "fuzzel";
          ime = lib.mkDefault "skk";
          mimeBrowser = lib.mkDefault "chromium";
          browser = lib.mkDefault "librewolf";
        };

        shell.private.enable = lib.mkDefault true;
        dev.podman.enable = lib.mkDefault true;
      };
    };

    age.secrets = {
      "passwd_tsukumo".file = ./passwd_tsukumo.age;
    };

    # for shell
    programs.fish.enable = lib.any (u: u.account.shell == "fish") (lib.attrValues config.custom.users);
    programs.zsh.enable = lib.any (u: u.account.shell == "zsh") (lib.attrValues config.custom.users);
    # nixpkgs' `programs.nushell` does not register the shell in `/etc/shells`
    # (unlike `programs.fish`/`programs.zsh`), so add it manually when any
    # user logs in with nushell.
    environment.shells =
      lib.mkIf (lib.any (u: u.account.shell == "nushell") (lib.attrValues config.custom.users))
        [
          pkgs.nushell
        ];

    security.sudo.enable = false;
    security.sudo-rs = {
      enable = true;
      wheelNeedsPassword = lib.mkDefault false;
    };
  };
}
