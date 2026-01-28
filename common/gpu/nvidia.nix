{ lib, config, ... }:
{
  options.custom.gpu.nvidia.enable = lib.mkEnableOption "nvidia GPU";
  config = lib.mkIf config.custom.gpu.nvidia.enable {
    hardware.graphics.enable = true;
    services.xserver.videoDrivers = [ "nvidia" ];
    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement = {
        enable = true;
      };
      open = false;
    };
    nix.settings = {
      extra-substituters = [ "https://cache.nixos-cuda.org" ];
      extra-trusted-public-keys = [ "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M=" ];
    };
  };
}
