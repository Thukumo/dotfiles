{ impermanence, ...}:

{
  system = "x86_64-linux";

  specialArgs = { };

  modules = [
    ./configuration.nix
    ./hardware-configuration.nix

    impermanence.nixosModules.impermanence

    {
      home-manager.sharedModules = [
        impermanence.homeManagerModules.impermanence
      ];

      home-manager.users."tsukumo" = {
        imports = [
          ./home-manager
        ];
      };
    }
  ];
}

