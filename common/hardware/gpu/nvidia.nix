{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.custom.hardware.gpu.nvidia.enable = lib.mkEnableOption "nvidia GPU";
  config = lib.mkIf config.custom.hardware.gpu.nvidia.enable {
    nixpkgs.config = {
      allowUnfreePackages = [
        pkgs.linuxPackages.nvidia_x11.pname
        pkgs.linuxPackages.nvidia_x11.settings.pname
      ];
      allowUnfreePredicate =
        pkg:
        builtins.any (
          l:
          builtins.elem l [
            lib.licenses.nvidiaCuda
            lib.licenses.nvidiaCudaRedist
          ]
        ) (lib.toList (pkg.meta.license or null));
    };
    hardware.graphics.enable = true;
    services.xserver.videoDrivers = [ "nvidia" ];
    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement = {
        enable = true;
      };
      open = true;
    };
    environment.systemPackages = with pkgs; [
      nvtopPackages.full
    ];
    nix.settings = {
      extra-substituters = [ "https://cache.nixos-cuda.org" ];
      extra-trusted-public-keys = [ "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M=" ];
    };
  };
}
