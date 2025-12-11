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

  outputs =
    {
      nixpkgs,
      home-manager,
      impermanence,
      nixvim,
      niri,
      ragenix,
      nix-index-database,
      ...
    }@inputs:
    let
      inherit (nixpkgs) lib;
      hostDirectories = lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./hosts);
      hosts = lib.mapAttrs (name: _: import (./hosts + "/${name}") inputs) hostDirectories;

      commonModules = name: [
        ./common
        {
          networking.hostName = name;
        }

        home-manager.nixosModules.home-manager
        {
          home-manager.sharedModules = [
            impermanence.homeManagerModules.impermanence
            nixvim.homeModules.nixvim
            niri.homeModules.niri
            ragenix.homeManagerModules.default
          ];
        }

        impermanence.nixosModules.impermanence

        nix-index-database.nixosModules.nix-index
        { programs.nix-index-database.comma.enable = true; }

        ragenix.nixosModules.default
      ];

      mkHost =
        name: host:
        lib.nixosSystem {
          inherit (host) system;
          specialArgs = {
            inherit inputs;
          }
          // (host.specialArgs or { });
          modules = (commonModules name) ++ (host.modules or [ ]);
        };
    in
    {
      formatter = lib.genAttrs (lib.unique (builtins.catAttrs "system" (builtins.attrValues hosts))) (
        name: nixpkgs.legacyPackages.${name}.nixfmt-tree
      );
      nixosConfigurations = lib.mapAttrs mkHost hosts;
    };
}
