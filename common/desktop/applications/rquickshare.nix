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
    let
      rqEnabled = builtins.any (userConfig: userConfig.desktop.apps.rquickshare.enable or false) (
        builtins.attrValues config.custom.users
      );
    in
    {
      home-manager.users = myLib.mkForEachUsers (user: user.custom.desktop.apps.rquickshare.enable) (
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
