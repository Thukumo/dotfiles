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
    };
  };

  home.file.".ssh/id_ed25519.pub".source = ../ssh/id_ed25519.pub;
}
