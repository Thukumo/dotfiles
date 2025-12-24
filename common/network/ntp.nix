{ lib, ... }:

{
  services.chrony = {
    enable = true;
    servers = [
      "ntp.nict.jp"
      "ntp.jst.mfeed.ad.jp"
    ]
    ++ map (n: "${toString n}.nixos.pool.ntp.org") (lib.range 0 3);
    initstepslew.threshold = 1.0;
  };
  environment.persistence."/persist".directories = [
    "/var/lib/chrony"
  ];
}
