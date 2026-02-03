{
  lib,
  myLib,
  config,
  ...
}:
{
  options.custom.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.desktop.apps.rquickshare.enable = lib.mkEnableOption "RQuickShare";
      }
    );
  };

  config = {
    home-manager.users = myLib.mkForEachUsers (user: user.custom.desktop.apps.rquickshare.enable) (
      _:
      { pkgs, ... }:
      {
        home.packages = [ pkgs.rquickshare ];
      }
    );
    
    # enable mDNS
    # Use mkDefault to allow conditional override without causing infinite recursion
    # (avahi creates system users which would affect config.users.users evaluation)
    services.avahi.enable = lib.mkDefault (
      builtins.any (userConfig: userConfig.desktop.apps.rquickshare.enable or false) (
        builtins.attrValues config.custom.users
      )
    );
    services.avahi.nssmdns4 = lib.mkDefault true;
    services.avahi.openFirewall = lib.mkDefault true;
    
    networking.firewall.allowedTCPPorts = lib.mkIf config.services.avahi.enable [ 42100 ];
  };
}
