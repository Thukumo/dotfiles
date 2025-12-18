{ lib, config, ... }:

{
  options.custom.dev.podman = {
    enable = lib.mkEnableOption "podman";
  };
  config = lib.mkIf config.custom.dev.podman.enable {
    virtualisation = {
      containers.enable = true;
      podman = {
        enable = true;
        dockerCompat = true;
        defaultNetwork.settings.dns_enabled = true;
      };
    };

    home-manager.users."tsukumo".imports = [
      ./podman.nix
    ];
  };
}
