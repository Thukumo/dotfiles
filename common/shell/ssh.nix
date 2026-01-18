{ pkgs, ... }:

{
  home.packages = [ pkgs.mosh ];
  home.sessionVariables = {
    MOSH_PREDICTION_DISPLAY = "always";
  };
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
  };
}
