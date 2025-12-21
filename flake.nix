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

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
      disko,
      nixos-generators,
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
        disko.nixosModules.disko
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
      nixosConfigurations = lib.mapAttrs mkHost hosts // {
        installer = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
            {
              networking.networkmanager.enable = lib.mkForce false;
              networking.wireless = {
                enable = true;
                networks = {
                  # ここにWi-Fiのパスワードを入れる
                  # "ESSID".psk = "pwd";
                };
              };
              # ホームディレクトリにあるキーペアと同一
              users.users.nixos.openssh.authorizedKeys.keys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKbmCSnxi4i+LHKTtZsX++GocB95+Px+uMGC0rywgiXe tsukumo@thinkpadx13-nix"
              ];
              services.avahi = {
                enable = true;
                hostName = "installer";
                nssmdns4 = true;
                publish = {
                  enable = true;
                  userServices = true;
                  addresses = true;
                };
              };
              documentation = {
                enable = false;
                nixos.enable = false;
              };
            }
          ];
        };
      };
    };
}
