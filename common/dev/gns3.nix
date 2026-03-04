{
  lib,
  config,
  pkgs,
  myLib,
  ...
}:
let
  cfg = config.custom.users;
in
{
  options.custom.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.dev.gns3 = {
          enable = lib.mkEnableOption "gns3";
        };
      }
    );
  };

  config = lib.mkIf (builtins.any (user: user.dev.gns3.enable or false) (builtins.attrValues cfg)) {
    virtualisation.libvirtd.enable = true;
    programs.wireshark.enable = true;

    environment.systemPackages = with pkgs; [
      ubridge
    ];
    security.wrappers.ubridge = {
      source = "${pkgs.ubridge}/bin/ubridge";
      capabilities = "cap_net_admin,cap_net_raw+ep";
      owner = "root";
      group = "ubridge";
      permissions = "u+rx,g+x,o+x";
    };
    users.groups.ubridge = {};

    users.users = lib.mapAttrs (name: userConfig: {
      extraGroups = lib.optionals (userConfig.dev.gns3.enable or false) [
        "gns3"
        "ubridge"
        "libvirtd"
        "wireshark"
        "kvm"
      ];
    }) cfg;

    home-manager.users = myLib.mkForEachUsers (user: user.custom.dev.gns3.enable or false) (
      user: _: {
        home.packages = with pkgs; [
          gns3-gui
          gns3-server
          xterm
          dynamips
          vpcs
          qemu_kvm
        ];
        home.persistence."/persist".directories = [
          "GNS3"
          ".config/GNS3"
        ];
      }
    );
  };
}
