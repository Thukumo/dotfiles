{ ... }:

{
  imports = [
    ./boot.nix
    ./networking.nix
    ./locale.nix
    ./users.nix
    ./desktop.nix
    ./secrets.nix
    ./power.nix
    ./nix.nix
    ./impersistence.nix
  ];
}
