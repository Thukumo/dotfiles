{
  lib,
  mkForEachUsers,
  ...
}:

{
  config = {
    home-manager.users = mkForEachUsers (user: user.custom.desktop.launcher == "fuzzel") (user: {
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
