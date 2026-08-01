{
  desktopLib,
  ...
}:
{
  config = {
    home-manager.users = desktopLib.mkHome (user: user.custom.desktop.apps.librewolf.enable or false) (
      _: _: {
        programs.librewolf = {
          enable = true;
        };
        home.persistence."/persist".directories = [
          ".config/librewolf"
        ];
      }
    );
  };
}
