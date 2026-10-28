_:

{
  system = "x86_64-linux";

  modules = [
    ./configuration.nix
    ./hardware.nix
    ./hardware-configuration.nix
    ./ingress.nix
    ./services
  ];
}
