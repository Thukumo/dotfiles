{ pkgs, lib, ... }:

{
 # home.activation = {
 #    parallelNoCitation = lib.hm.dag.entryAfter ["writeBoundary"] ''
 #      ${pkgs.parallel}/bin/parallel --citation
 #    '';
 #  };
  home.packages = with pkgs; [
    pandoc
    typst
    parallel
    (pkgs.writeShellScriptBin "convd-md2pdf" (builtins.readFile ./convd-md2pdf.sh))
  ];
}
