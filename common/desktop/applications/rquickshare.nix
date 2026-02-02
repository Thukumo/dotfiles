{
  lib,
  mkForEachUsers,
  config,
  ...
}:
{
  options.users.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (_: {
        options.custom.desktop.apps.rquickshare.enable = lib.mkEnableOption "RQuickShare";
      })
    );
  };

  config =
    # lib.mkIf (builtins.any (user: user.custom.desktop.apps.rquickshare.enable) config.users.users)
    {
      home-manager.users = mkForEachUsers (user: user.custom.desktop.apps.rquickshare.enable) (
        user:
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
