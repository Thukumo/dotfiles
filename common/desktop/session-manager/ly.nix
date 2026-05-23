{
  lib,
  config,
  ...
}:

{
  config =
    lib.mkIf (config.custom.desktop.anyEnabled && config.custom.desktop.sessionManager == "ly")
      {
        services.displayManager.ly.enable = true;
      };
}
