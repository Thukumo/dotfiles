{
  pkgs,
  lib,
  myConfig,
  ...
}:

lib.mkIf myConfig.shell.chat.enable {
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
