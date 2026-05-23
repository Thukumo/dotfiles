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
      extraConfig.pipewire = {
        "99-buffer-fix" = {
          "context.properties" = {
            "default.clock.quantum" = 1024;
            "default.clock.min-quantum" = 1024;
            "default.clock.max-quantum" = 2048;
          };
        };
        "99-high-res" = {
          "context.properties" = {
            # "default.clock.rate" = 192000;
            "default.clock.allowed-rates" = [
              44100
              48000
              88200
              96000
              176400
              192000
            ];
          };
          "stream.properties" = {
            "resample.quality" = 10;
            "channelmix.normalize" = false;
          };
        };
      };
    };
  };
}
