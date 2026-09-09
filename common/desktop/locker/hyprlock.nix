{
  config,
  lib,
  desktopLib,
  myLib,
  ...
}:

{
  security.pam.services.hyprlock = lib.mkIf (myLib.anyUser config (
    user: user.desktop.locker == "hyprlock"
  )) { };

  home-manager.users = desktopLib.mkHome (user: user.custom.desktop.locker == "hyprlock") (_: {
    programs.hyprlock = {
      enable = true;
      settings = {
        general = {
          no_fade_in = false;
          grace = 0;
          disable_loading_bar = true;
        };

        background = lib.mkForce [
          {
            path = "screenshot";
            blur_passes = 3;
            blur_size = 8;
            noise = 0.0117;
          }
        ];
      };
    };
  });
}
