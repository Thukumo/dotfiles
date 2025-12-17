{ pkgs, ... }:

{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "what";
      text = builtins.readFile ./what.sh;
    })
  ];
}
