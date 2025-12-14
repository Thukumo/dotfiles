{ ... }:

{
  imports = [
    ./boot.nix
    ./networking.nix
    ./locale.nix
    ./users.nix
    ./secrets.nix
    ./power.nix
    ./nix.nix
    ./impersistence.nix
    ./fonts.nix
    ./modules
  ];
}
