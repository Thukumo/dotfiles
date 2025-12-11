{ config, pkgs, ... }:

{
  # home-managerのSteamは正常に動作しなさそう...?
  # home.packages = with pkgs; [
  #   steam
  # ];
  home.persistence."/persist/${config.home.homeDirectory}".directories = [
    ".local/share/Steam"
    ".local/share/applications" # たぶんアプリランチャーにゲームを表示するために入れてる
  ];
  home.sessionVariables = {
  };
  xdg.mimeApps = {
  };
}
