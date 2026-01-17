{
  lib,
  config,
  ...
}:

{
  config = lib.mkIf config.custom.desktop.pipewire.enable {
    security.rtkit.enable = true;
  };
}
