{
  desktopLib,
  ...
}:
{
  config = {
    home-manager.users = desktopLib.mkHome (user: user.custom.desktop.mimeBrowser != null) (
      user:
      let
        desktopFile =
          {
            chromium = "chromium-browser.desktop";
            google-chrome = "google-chrome.desktop";
            librewolf = "librewolf.desktop";
          }
          .${user.custom.desktop.mimeBrowser};
      in
      {
        xdg.mimeApps = {
          enable = true;
          defaultApplications = {
            "x-scheme-handler/http" = [ desktopFile ];
            "x-scheme-handler/https" = [ desktopFile ];
            "text/html" = [ desktopFile ];
          };
        };
      }
    );
  };
}
