{
  lib,
  config,
  myLib,
  ...
}:
let
  anyUserEnabled = myLib.anyUser config (user: user.desktop.apps.localsend.enable);
in
{
  config = lib.mkIf anyUserEnabled {
    programs.localsend = {
      enable = true;
      openFirewall = true;
    };
  };
}
