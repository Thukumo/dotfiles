{ config, lib, ... }:
{
  _module.args = {
    mkEnabledOption = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };
}
