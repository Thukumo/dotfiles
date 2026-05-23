{
  lib,
  desktopLib,
  config,
  ...
}:
{
  config =
    let
      rqEnabled = builtins.any (userConfig: userConfig.desktop.apps.rquickshare.enable or false) (
        builtins.attrValues config.custom.users
      );
    in
    {
      home-manager.users = desktopLib.mkHome (user: user.custom.desktop.apps.rquickshare.enable) (
        _:
        { pkgs, ... }:
        {
          home.packages = [ pkgs.rquickshare ];
        }
      );

      # enable mDNS (only when RQuickShare is enabled; avoid defining `false`)
      services.avahi.enable = lib.mkIf rqEnabled (lib.mkDefault true);
      services.avahi.nssmdns4 = lib.mkIf rqEnabled (lib.mkDefault true);
      services.avahi.openFirewall = lib.mkIf rqEnabled (lib.mkDefault true);

      networking.firewall.allowedTCPPorts = lib.mkIf rqEnabled [ 42100 ];
    };
}
