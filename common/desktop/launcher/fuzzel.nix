{
  myLib,
  config,
  lib,
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
                font = lib.mkForce "${config.stylix.fonts.monospace.name}:size=18";
              };
            };
          };
        });
  };
}
