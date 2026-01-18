{ mkForEachUsers, ... }:

{
  networking.hosts = {
    "482:d00b:576e:de40:7f7a:564f:515f:cb7a" = [
      "f-51b"
    ];
    "4d8:de15:85dd:7fa4:493e:f1a4:6961:bd9c" = [ "thinkpad-x13-nix" ];
  };
  home-manager.users = mkForEachUsers (_: true) {
    programs.ssh.matchBlocks = {
      "f-51b" = {
        port = 8022;
      };
    };
  };
}
