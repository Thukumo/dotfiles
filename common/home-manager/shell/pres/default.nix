{ pkgs, ... }:

{
  home.packages = with pkgs; [
    (pkgs.writeShellApplication {
      name = "pres";
      runtimeInputs = with pkgs; [
        gnutar
        zstd
      ];
      text = builtins.readFile ./pres.sh;
    })
  ];
}
