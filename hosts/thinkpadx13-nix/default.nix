{ nixos-hardware, ... }:

{
  system = "x86_64-linux";

  specialArgs = { };

  modules = [
    ./configuration.nix
    ./hardware-configuration.nix
    nixos-hardware.nixosModules.lenovo-thinkpad-x13-amd
  ];
}
