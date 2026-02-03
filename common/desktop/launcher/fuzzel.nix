{
  lib,
  myLib,
  config,
  ...
}:

{
  config = {
    home-manager.users = myLib.mkForEachUsers (user: user.custom.desktop.launcher or null == "fuzzel") (user: {
      programs.fuzzel = {
        enable = true;
        settings = {
          main = {
            use-bold = "yes";
            dpi-aware = "no";
            font = "Adwaita Mono Nerd Font:size=18";
          };
        };
      };
    });
  };
}
