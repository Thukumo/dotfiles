{
  desktopLib,
  config,
  lib,
  ...
}:

{
  config = {
    home-manager.users = desktopLib.mkHome (user: user.custom.desktop.launcher == "fuzzel") (_user: {
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
