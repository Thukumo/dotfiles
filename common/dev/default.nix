{ lib, config, mkForEachUsers, ... }:

{
  options.users.users = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options.custom.dev.podman = {
        enable = lib.mkEnableOption "podman";
      };
    });
  };

  config = {
    virtualisation = {
      containers.enable = true;
      podman = {
        enable = true;
        dockerCompat = true;
        defaultNetwork.settings.dns_enabled = true;
      };
    };

    home-manager.users = mkForEachUsers (user: user.custom.dev.podman.enable) (user: {
      imports = [
        ./podman.nix
      ];
    });
  };
}
