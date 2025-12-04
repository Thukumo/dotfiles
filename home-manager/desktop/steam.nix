{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    steam
  ];
  home.persistence."/persist/${config.home.homeDirectory}".directories = [
    ".local/share/Steam"
    ".local/share/applications" # たぶんランチャーにゲームを表示するために入れてる
  ];
 home.sessionVariables = {
  };
  xdg.mimeApps = {
  };
}

