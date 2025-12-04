{ config, pkgs, lib, ... }:

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
  programs.chromium = rec {
    enable = true;
    extensions = [
      "gighmmpiobklfepjocnamgkkbiglidom" # AdBlock
      "ammoloihpcbognfddfjcljgembpibcmb" # JShelter
    ];
    # extraOpts = lib.genAttrs extensions (_: {
    #     runtime_allowed_hosts = [ "*://*/*" ];
    #     incognito_mode = "split";
    #   });
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

