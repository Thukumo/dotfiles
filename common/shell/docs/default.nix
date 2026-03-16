{ pkgs, ... }:

{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "gen-docs";
      runtimeInputs = [ pkgs.nix ];
      text = builtins.readFile ./gen-docs.sh;
    })
  ];
}
