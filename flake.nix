{
  description = "NixOS Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";

    nix-index-database.url = "github:nix-community/nix-index-database";

    affinity-nix.url = "github:mrshmllow/affinity-nix";

    nixvim.url = "github:nix-community/nixvim";

    niri.url = "github:sodiboo/niri-flake";

    ragenix.url = "github:yaxitech/ragenix";
  };

  outputs = { self, nixpkgs, home-manager, impermanence, affinity-nix, nixvim, niri, ragenix, ... }@inputs: 
    let
      configurations = {
        "thinkpadx13-nix" = {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };

          modules = [
            impermanence.nixosModules.impermanence

            ./configuration.nix

            # { environment.systemPackages = [affinity-nix.packages.x86_64-linux.v3]; }

            { home-manager.sharedModules = [
              nixvim.homeModules.nixvim
              niri.homeModules.niri
              impermanence.homeManagerModules.impermanence
            ]; }
          ];
        };
      };
      genConfig = name: val: nixpkgs.lib.nixosSystem (val // {
        modules = val.modules ++ [
          {
            networking.hostName = name;
            nixpkgs.config.allowUnfree = true;
          }

          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          }

          inputs.nix-index-database.nixosModules.nix-index
          { programs.nix-index-database.comma.enable = true; }

          ragenix.nixosModules.default
        ]; 
      });
    in {
      nixosConfigurations = nixpkgs.lib.mapAttrs genConfig configurations;
    };
}

