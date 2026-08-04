{
  lib,
  config,
  ...
}:
let
  anyUserEnabled = lib.any (user: user.desktop.apps.localsend.enable) (
    builtins.attrValues config.custom.users
  );
in
{
  config = lib.mkIf anyUserEnabled {
    programs.localsend = {
      enable = true;
      openFirewall = true;
    };
  };
}
