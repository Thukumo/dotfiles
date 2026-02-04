{ config, lib, ... }:
{
  _module.args.myLib = {
    # Iterate only users explicitly present in `config.custom.users`.
    # This avoids evaluating conditions for users with no custom config,
    # and keeps condition mistakes as hard evaluation errors.
    mkForEachUsers =
      condition: content:
      lib.mkMerge (
        lib.mapAttrsToList (
          name: userCfg:
          let
            sysUser =
              if builtins.hasAttr name config.users.users then
                config.users.users.${name}
              else
                throw "custom.users.${name} is defined, but users.users.${name} does not exist (typo?)";

            user' = sysUser // {
              name = name;
              custom = userCfg;
            };
          in
          lib.mkIf (sysUser.isNormalUser && (condition user')) {
            "${name}" = if builtins.isFunction content then content user' else content;
          }
        ) config.custom.users
      );

    mkEnabledOption = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };
}
