_:

{
  networking = {
    networkmanager = {
      enable = true;
      dns = "systemd-resolved";
    };
    nameservers = [
      "2606:4700:4700::1111"
      "2606:4700:4700::1001"
      "1.1.1.1"
      "1.0.0.1"
      "2620:fe::fe"
      "9.9.9.9"
    ];
  };

  services.resolved = {
    enable = true;
    settings = {
      Resolve = {
        DNSSEC = "allow-downgrade";
        DNSOverTLS = "opportunistic";
        Domains = [ "~." ];
        FallbackDNS = null;
      };
    };
  };
}
