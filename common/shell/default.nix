{ mkForEachUsers, ... }:

{
  home-manager.users = mkForEachUsers (user: true) (user: {
    imports = [
      ./cli.nix
      ./git.nix
      ./chat.nix
      ./fish.nix
      ./nixvim.nix
      ./pres
      ./what
      ./convd-md2pdf
    ];
  });
}
