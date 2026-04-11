{
  myLib,
  ...
}:

{
  config = {
    home-manager.users =
      myLib.mkForEachUsers (user: user.custom.desktop.terminal or null == "foot")
        (user: {
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
