{ config, ... }:

{
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/etc/NetworkManager/system-connections"
      "/var/lib/NetworkManager/system-connections"
      "/var/lib/bluetooth"
      "/var/lib/systemd/timers"
      "/var/lib/nixos"
      "/var/log"
      (builtins.dirOf config.custom.secrets.secretKey) # これsecretsに置くべき？
    ];
    files = [ "/etc/machine-id" ];
  };
  # for "home-manager" impermanence
  programs.fuse.userAllowOther = true;
  home-manager.users."tsukumo".imports = [
    ./home-impermanence.nix
  ];
}
