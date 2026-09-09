{
  config,
  lib,
  desktopLib,
  myLib,
  ...
}:

{
  security.pam.services.swaylock = lib.mkIf (myLib.anyUser config (
    user: user.desktop.locker == "swaylock"
  )) { };

  home-manager.users = desktopLib.mkHome (user: user.custom.desktop.locker == "swaylock") (_: {
    programs.swaylock.enable = true;
  });
}
