{
  lib,
  config,
  inputs,
  ...
}:
let
  myCfg = config.custom.security.gaze;
in
{
  imports = [ inputs.gaze.nixosModules.default ];

  options.custom.security.gaze = {
    enable = lib.mkEnableOption "Gaze facial authentication (face unlock)";
    gui = lib.mkEnableOption "the Gaze GTK GUI for enrolling faces" // {
      default = true;
    };

    pamServices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "sudo"
        "polkit-1"
        "login"
        "hyprlock"
      ];
      description = "PAM services to enable Gaze face authentication for.";
    };
  };

  config = lib.mkIf myCfg.enable {
    services.gaze = {
      enable = true;
      gui.enable = myCfg.gui;
      mutableConfig = false;
      pam.defaultServices = myCfg.pamServices;
    };

    environment.persistence."/persist".directories = [
      "/var/lib/gaze"
      "/var/cache/gaze"
    ];
  };
}
