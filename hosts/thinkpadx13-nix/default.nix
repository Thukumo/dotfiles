{ impermanence, ...}:

{
  system = "x86_64-linux";

  specialArgs = { };

  modules = [
    ./hardware-configuration.nix
    ./hardware.nix

    impermanence.nixosModules.impermanence

    {
      home-manager.sharedModules = [
        impermanence.homeManagerModules.impermanence
      ];
    }
  ];
}

