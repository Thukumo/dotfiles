{
  desktopLib,
  ...
}:

{
  config = {
    home-manager.users = desktopLib.mkHome (user: user.custom.desktop.terminal == "foot") (_user: {
      programs.foot = {

        enable = true;
        settings = {
          mouse = {
            hide-when-typing = "yes";
          };
        };
      };
    });
  };
}
