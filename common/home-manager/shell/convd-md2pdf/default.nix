{ pkgs, ... }:

{
 # home.activation = {
 #    parallelNoCitation = lib.hm.dag.entryAfter ["writeBoundary"] ''
 #      ${pkgs.parallel}/bin/parallel --citation
 #    '';
 #  };
  home.packages = with pkgs; [
    (pkgs.writeShellApplication {
      name = "convd-md2pdf";
      runtimeInputs = with pkgs; [
        pandoc
        typst
        parallel
      ];
      text = builtins.readFile ./convd-md2pdf.sh;
    })
  ];
}
