{ osConfig, lib, ... }:
lib.mkIf (osConfig.age.secrets ? "home-manager_key") {
  age = {
    identityPaths = [ (toString osConfig.age.secrets."home-manager_key".path) ];
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
