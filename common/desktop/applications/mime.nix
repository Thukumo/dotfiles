{
  desktopLib,
  ...
}:
{
  config = {
    home-manager.users = desktopLib.mkHome (user: user.custom.desktop.mimeBrowser != null) (
      user:
      let
        inherit ((desktopLib.browserInfo user.custom.desktop.mimeBrowser)) desktopFile;
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
