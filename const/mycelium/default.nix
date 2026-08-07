{
  myLib,
  config,
  lib,
  ...
}:

{
  options.custom.mycelium.hosts = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          ipv6 = lib.mkOption {
            type = lib.types.str;
            description = "Mycelium IPv6 address of this host";
          };
          hostname = lib.mkOption {
            type = lib.types.str;
            description = "Hostname that other machines resolve to this address";
          };
        };
      }
    );
    default = { };
    description = "Mycelium IPv6 addresses of all machines (single source of truth)";
  };

  config = {
    custom.mycelium.hosts = {
      "16x-aurora" = {
        ipv6 = "482:d00b:576e:de40:7f7a:564f:515f:cb7a";
        hostname = "f-51b";
      };
      "thinkpadx13-nix" = {
        ipv6 = "4d8:de15:85dd:7fa4:493e:f1a4:6961:bd9c";
        hostname = "thinkpad-x13-nix";
      };
      "mouse-3" = {
        ipv6 = "488:9c35:edc2:14f9:691a:53c:ef01:cb25";
        hostname = "mouse-3";
      };
    };

    networking.hosts = lib.mapAttrs' (
      _: host: lib.nameValuePair host.ipv6 [ host.hostname ]
    ) config.custom.mycelium.hosts;

    home-manager.users = myLib.mkForEachUsers config (_: true) {
      programs.ssh.settings = {
        "Host f-51b" = {
          Port = 8022;
        };
      };
    };
  };
}
