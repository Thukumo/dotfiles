{
  lib,
  config,
  ...
}:

let
  cfg = config.custom.power;
in
{
  options.custom.power = {
    allowHibernate = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether hibernation and suspend-then-hibernate are allowed.";
    };

    sleepAction = lib.mkOption {
      type = lib.types.enum [
        "suspend"
        "suspend-then-hibernate"
      ];
      readOnly = true;
      default = if cfg.allowHibernate then "suspend-then-hibernate" else "suspend";
      description = "Sleep action derived from allowHibernate.";
    };
  };

  config = {
    systemd.sleep.settings.Sleep = {
      # Keep the session on disk before the battery runs out.
      HibernateDelaySec = "30min";
      AllowHibernation = cfg.allowHibernate;
      AllowSuspendThenHibernate = cfg.allowHibernate;
    };

    services.logind.settings.Login = {
      HandleLidSwitch = cfg.sleepAction;
      HandleSuspendKey = cfg.sleepAction;
      HandleHibernateKey = if cfg.allowHibernate then "hibernate" else "ignore";
    };
  };
}
