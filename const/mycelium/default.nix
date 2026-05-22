{ myLib, ... }:

{
  networking.hosts = {
    "482:d00b:576e:de40:7f7a:564f:515f:cb7a" = [
      "f-51b"
    ];
    "4d8:de15:85dd:7fa4:493e:f1a4:6961:bd9c" = [ "thinkpad-x13-nix" ];
    "40f:4972:ada8:df1b:14d5:bfe:b7de:961d" = [ "mouse-3" ];
  };
  home-manager.users = myLib.mkForEachUsers (_: true) {
    programs.ssh.settings = {
      "Host f-51b" = {
        Port = 8022;
      };
    };
  };
}
