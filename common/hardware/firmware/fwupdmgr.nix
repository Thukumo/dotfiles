{ lib, config, ... }:

{
  options.custom.hardware.fwupdmgr.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Whether to enable fwupdmgr.";
  };

  config = lib.mkIf config.custom.hardware.fwupdmgr.enable {
    services.fwupd.enable = true;
  };
}
