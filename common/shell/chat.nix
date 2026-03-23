{ pkgs, ... }:

{
  home.packages = with pkgs; [
    gemini-cli
    github-copilot-cli
    # (github-copilot-cli.overrideAttrs (_: {
    #   postInstall = "";
    # }))
  ];
  home.persistence."/persist".directories = [
    ".gemini"
  ];
}
