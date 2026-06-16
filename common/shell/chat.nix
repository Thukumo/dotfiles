{ pkgs, ... }:

{
  home.packages = with pkgs; [
    github-copilot-cli
  ];
  programs.antigravity-cli = {
    enable = true;
  };
  home.persistence."/persist".directories = [
    ".gemini"
  ];
}
