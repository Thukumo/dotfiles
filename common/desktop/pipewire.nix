{
  lib,
  config,
  ...
}:

{
  config = lib.mkIf config.custom.desktop.pipewire.enable {
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      extraConfig.pipewire."99-buffer-fix" = {
        "context.properties" = {
          "default.clock.quantum" = 1024;
          "default.clock.min-quantum" = 1024;
          "default.clock.max-quantum" = 2048;
        };
      };
    };
  };
}
