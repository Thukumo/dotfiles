{
  desktopLib,
  ...
}:
{
  config = {
    home-manager.users = desktopLib.mkHome (user: user.custom.desktop.apps.qutebrowser.enable) (_: {
      programs.qutebrowser = {
        enable = true;
        settings.tabs.position = "left";
      };
      home.persistence."/persist".directories = [
      ];
    });
  };
}
