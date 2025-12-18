{ pkgs, config, ... }:

{
  home.packages = with pkgs; [
    gemini-cli
    github-copilot-cli
  ];
  home.persistence."/persist${config.home.homeDirectory}".directories = [
    ".gemini"
  ];
}
