{
  myLib,
  ...
}:

{
  config = {
    home-manager.users =
      myLib.mkForEachUsers (user: user.custom.desktop.launcher or null == "fuzzel")
        (user: {
          programs.fuzzel = {
            enable = true;
            settings = {
              main = {
                use-bold = "yes";
              };
            };
          };
        });
  };
}
