{
  desktopLib,
  inputs,
  ...
}:
{
  config = {
    home-manager.users = desktopLib.mkHome (user: user.custom.desktop.apps.sidra.enable or false) (
      _:
      { pkgs, ... }:
      {
        home.packages = [ inputs.sidra.packages.${pkgs.stdenv.hostPlatform.system}.default ];
        home.persistence."/persist".directories = [
          ".config/Sidra"
        ];
      }
    );
  };
}
