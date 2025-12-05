{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    chromium
    mattermost-desktop
    discord
    google-chrome
    libreoffice-still
    zoom-us
    gnome-disk-utility
    blender
    # davinci-resolve
    rquickshare
  ];
  # Mattermost Desktopが~/.config/autostart/electron.desktopを作ってきて困るので、
  # 先に/dev/nullへのシンボリックリンクにしておく
  xdg.configFile = {
    "autostart/electron.desktop".source = config.lib.file.mkOutOfStoreSymlink "/dev/null";
  };
  home.persistence."/persist/${config.home.homeDirectory}".directories = [
    ".config/google-chrome"
    ".config/discord"
    ".config/Mattermost"
  ];
  programs.chromium = {
    enable = true;
    extensions = [
      "gighmmpiobklfepjocnamgkkbiglidom" # AdBlock
      "ammoloihpcbognfddfjcljgembpibcmb" # JShelter
    ];
  };
  home.sessionVariables = {
  };
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/http" = [ "chromium.desktop" ];
      "x-scheme-handler/https" = [ "chromium.desktop" ];
      "text/html" = [ "chromium.desktop" ];
    };
  };
}

