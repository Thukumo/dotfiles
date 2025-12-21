{ config, lib, ... }:
{
  _module.args = {
    mkForEachUsers =
      filterFunc: contentOrFunc:
      lib.mkMerge (
        lib.mapAttrsToList (
          name: userCfg:
          lib.mkIf (userCfg.isNormalUser && filterFunc userCfg) {
            "${name}" = if builtins.isFunction contentOrFunc then contentOrFunc userCfg else contentOrFunc;
          }
        ) config.custom.users
      );
  };
}
