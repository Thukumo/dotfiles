{ config, lib, ... }:
{
  _module.args = {
    mkForEachUsers =
      condition: content:
      lib.mkMerge (
        lib.mapAttrsToList (
          name: user:
          lib.mkIf (user.isNormalUser && (condition user)) {
            "${name}" = if builtins.isFunction content then content user else content;
          }
        ) config.users.users
      );
  };
}
