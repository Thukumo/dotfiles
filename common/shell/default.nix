{
  lib,
  myLib,
  config,
  pkgs,
  ...
}:

{
  options.custom.users = myLib.mkUserOption {
    options.shell = {
      private.enable = lib.mkEnableOption "private shell secrets";
      chat.enable = myLib.mkEnabledOption "chat CLIs (GitHub Copilot CLI / Antigravity CLI)";
    };
  };

  config = {
    custom.secrets.access.home = lib.mapAttrs (
      _: user:
      if user.shell.private.enable then
        {
          ssh_key = {
            file = ./ssh/ssh-key_tsukumo.age;
            path = ".ssh/id_ed25519";
            trusted = true;
            programs = [
              "ssh"
              "git"
              "ssh-keygen"
            ];
          };

          github_credential = {
            file = ./git/gh_hosts_tsukumo.age;
            path = ".config/gh/hosts.yml";
            trusted = true;
            programs = [
              "gh"
              "git"
            ];
          };

          nix_access_tokens = {
            file = ./private/nix-access-tokens.age;
            path = ".config/nix/access-tokens";
            trusted = true;
            programs = [ "nix" ];
          };
        }
      else
        { }
    ) config.custom.users;

    home-manager.users = lib.mkMerge [
      (myLib.mkForEachUsers config (_: true) (_: {
        imports = myLib.mkImportModules ./. [ "private" ];
      }))
      (myLib.mkForEachUsers config (user: user.custom.shell.private.enable) {
        imports = [ ./private ];
        home.persistence."/persist".files = [ ".config/age/home-manager_key" ];
      })
    ];

    nixpkgs.config.allowUnfreePackages = [
      pkgs.github-copilot-cli.pname
      pkgs.antigravity-cli.pname
    ];
  };
}
