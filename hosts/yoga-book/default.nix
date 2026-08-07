{ nur, ... }:

{
  system = "x86_64-linux";

  modules = [
    ./configuration.nix
    ./hardware-configuration.nix

    # nur.repos.tsukumo.nixosModules.yogabook
    nur.nixosModules.yogabook
  ];
}
