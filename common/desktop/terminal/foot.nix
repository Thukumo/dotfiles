{
  desktopLib,
  ...
}:

{
  config = {
    home-manager.users =
      desktopLib.mkHome (user: user.custom.desktop.terminal or null == "foot")
        (_user: {
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
