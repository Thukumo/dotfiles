{
  lib,
  config,
  myLib,
  ...
}:
let
  anyUserEnabled = lib.any (user: user.desktop.apps.localsend.enable or false) (
    builtins.attrValues config.custom.users
  );
in
{
  options.custom.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.desktop.apps.localsend.enable = lib.mkEnableOption "LocalSend";
      }
    );
  };

  config = lib.mkIf anyUserEnabled {
    programs.localsend = {
      enable = true;
      openFirewall = true;
    };
  };
}
