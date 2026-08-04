{
  desktopLib,
  inputs,
  pkgs,
  ...
}:
{
  config = {
    home-manager.users = desktopLib.mkHome (user: user.custom.desktop.apps.sidra.enable) (
      _: _: {
        home.packages = [ inputs.sidra.packages.${pkgs.stdenv.hostPlatform.system}.default ];
        home.persistence."/persist".directories = [
          ".config/Sidra"
        ];
      }
    );
  };
}
