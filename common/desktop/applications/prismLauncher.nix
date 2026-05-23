{
  desktopLib,
  ...
}:
{
  config = {
    home-manager.users = desktopLib.mkHome (user: user.custom.desktop.apps.prismLauncher.enable) (
      _:
      { pkgs, ... }:
      {
        home.packages = [ pkgs.prismlauncher ];
        home.persistence."/persist".directories = [
          ".local/share/prismlauncher"
        ];
      }
    );
  };
}
