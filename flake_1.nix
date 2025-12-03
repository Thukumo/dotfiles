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

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri.url = "github:sodiboo/niri-flake";
  };

  outputs = { self, nixpkgs, home-manager, impermanence, affinity-nix, nixvim, ... }@inputs:
    let
      inherit (nixpkgs) lib;
      hostDirectories = lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./hosts);
      hosts = lib.mapAttrs (name: _: import (./hosts + "/${name}") { inherit inputs; }) hostDirectories;
      commonModules = name: [
        inputs.impermanence.nixosModule
        inputs.home-manager.nixosModules.home-manager
        {
          networking.hostName = name;
          nixpkgs.config.allowUnfree = true;
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.sharedModules = [ nixvim.homeModules.nixvim ];
        }
        inputs.nix-index-database.nixosModules.nix-index
        { programs.nix-index-database.comma.enable = true; }
      ];
      mkHost = name: host:
        lib.nixosSystem {
          system = host.system or "x86_64-linux";
          specialArgs = (host.specialArgs or {}) // {
            inherit inputs;
            hostName = name;
          };
          modules = (host.modules or []) ++ (commonModules name);
        };
    in {
      nixosConfigurations = lib.mapAttrs mkHost hosts;
    };
}

