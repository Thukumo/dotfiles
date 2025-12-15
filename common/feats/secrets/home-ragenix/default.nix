{ osConfig, ... }:

{
  age = {
    identityPaths = [ (toString osConfig.age.secrets."home-manager_key".path) ];
    secrets = {
      "ssh_key" = {
        file = ./secrets/ssh-key_tsukumo.age;
        path = ".ssh/id_ed25519";
      };
      "github_credential" = {
        file = ./secrets/gh_hosts_tsukumo.age;
        path = ".config/gh/hosts.yml";
      };
    };
  };
  home.file.".ssh/id_ed25519.pub".source = ./id_ed25519.pub;
}
