{
  desktopLib,
  ...
}:
{
  config = {
    home-manager.users =
      desktopLib.mkHome (user: user.custom.desktop.apps.stirling-pdf.enable or false)
        (
          _:
          { pkgs, ... }:
          {
            home.packages = [ pkgs.stirling-pdf-desktop ];
          }
        );
  };
}
