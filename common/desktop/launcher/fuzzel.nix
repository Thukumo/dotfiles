{
  lib,
  mkForEachUsers,
  config,
  ...
}:

{
  config = {
    home-manager.users = mkForEachUsers (user: config.custom.users.${user.name}.desktop.launcher or null == "fuzzel") (user: {
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
