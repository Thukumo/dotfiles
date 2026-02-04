{
  config,
  lib,
  pkgs,
  myLib,
  ...
}:
{
  options.custom.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.desktop.vr.enable = lib.mkEnableOption "VR support";
      }
    );
  };

  config =
    let
      vrEnabled = builtins.any (user: user.desktop.vr.enable or false) (builtins.attrValues config.custom.users);
    in
    {
      environment.systemPackages = lib.mkIf vrEnabled (with pkgs; [
        wayvr
        opencomposite
      ]);

      services.wivrn = lib.mkIf vrEnabled {
        enable = true;
        autoStart = true;
        defaultRuntime = true;
        openFirewall = true;
      };

      # Enable Avahi daemon for service discovery, required by wivrn.
      # Only set values when VR is enabled (avoid writing an explicit `false`,
      # which can conflict with other modules also using mkDefault).
      services.avahi.enable = lib.mkIf vrEnabled (lib.mkDefault true);
      services.avahi.publish.enable = lib.mkIf vrEnabled (lib.mkDefault true);
      services.avahi.publish.userServices = lib.mkIf vrEnabled (lib.mkDefault true);

      home-manager.users = myLib.mkForEachUsers (user: user.custom.desktop.vr.enable or false) (_: {
        home.persistence."/persist".directories = [
          ".config/wivrn"
          ".config/wayvr"
        ];
      });
    };
}
