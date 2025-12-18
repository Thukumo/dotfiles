{ ... }:

{
  system = "x86_64-linux";

  specialArgs = { };

  modules = [
    ./configuration.nix
    ./hardware-configuration.nix
  ];
}
