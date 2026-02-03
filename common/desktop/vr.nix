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

  config = {
    environment.systemPackages = lib.mkIf (builtins.any (user: user.desktop.vr.enable or false) (builtins.attrValues config.custom.users)) (with pkgs; [
      wayvr
      opencomposite
    ]);
    services.wivrn = lib.mkIf (builtins.any (user: user.desktop.vr.enable or false) (builtins.attrValues config.custom.users)) {
      enable = true;
      autoStart = true;
      defaultRuntime = true;
      openFirewall = true;
    };

    # Enable Avahi daemon for service discovery, required by wivrn
    # Use mkDefault to allow conditional override without causing infinite recursion
    # Each attribute is set individually to avoid overriding settings from other modules.
    services.avahi.enable = lib.mkDefault (builtins.any (user: user.desktop.vr.enable or false) (builtins.attrValues config.custom.users));
    services.avahi.publish.enable = lib.mkDefault (builtins.any (user: user.desktop.vr.enable or false) (builtins.attrValues config.custom.users));
    services.avahi.publish.userServices = lib.mkDefault (builtins.any (user: user.desktop.vr.enable or false) (builtins.attrValues config.custom.users));

    home-manager.users = myLib.mkForEachUsers (user: user.custom.desktop.vr.enable or false) (_: {
      home.persistence."/persist".directories = [
        ".config/wivrn"
        ".config/wayvr"
      ];
    });
  };
}
