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

  config =
    # lib.mkIf (builtins.any (user: config.custom.users.${user.name}.desktop.apps.rquickshare.enable) config.users.users)
    {
      home-manager.users = myLib.mkForEachUsers (user: config.custom.users.${user.name}.desktop.apps.rquickshare.enable) (
        _:
        { pkgs, ... }:
        {
          home.packages = [ pkgs.rquickshare ];
        }
      );
      # enable mDNS
      services.avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
      };
      networking.firewall.allowedTCPPorts = [ 42100 ];
    };
}
