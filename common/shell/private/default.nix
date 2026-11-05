{ config, ... }:
{
  age = {
    identityPaths = [ "${config.home.homeDirectory}/.config/age/home-manager_key" ];
    secrets = {
      "ssh_key" = {
        file = ../ssh/ssh-key_tsukumo.age;
        path = ".ssh/id_ed25519";
      };
      "github_credential" = {
        file = ../git/gh_hosts_tsukumo.age;
        path = ".config/gh/hosts.yml";
      };
      "nix_access_tokens" = {
        file = ./nix-access-tokens.age;
        path = ".config/nix/access-tokens";
        mode = "0400";
      };
    };
  };

  xdg.configFile."nix/nix.conf".text = ''
    !include ~/.config/nix/access-tokens
  '';

  home.file.".ssh/id_ed25519.pub".source = ../ssh/id_ed25519.pub;
}
