{
  lib,
  myLib,
  ...
}:
{
  options.custom.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.dev.aider = {
          enable = lib.mkEnableOption "aider";
        };
      }
    );
  };

  config = {
    home-manager.users = myLib.mkForEachUsers (user: user.custom.dev.aider.enable or false) (
      user:
      { myConfig, ... }:
      {
        programs.aider-chat = {
          enable = true;
        };
      }
    );
  };
}
