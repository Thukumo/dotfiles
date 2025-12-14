{ config, ... }:

{
  home.persistence."/persist/${config.home.homeDirectory}".directories = [
    ".local/share/Steam"
    ".local/share/applications" # たぶんアプリランチャーにゲームを表示するために入れてる
  ];
  home.sessionVariables = {
  };
  xdg.mimeApps = {
  };
}
