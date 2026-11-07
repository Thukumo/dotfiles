{
  custom.secrets.access = {
    system = {
      cloudflared_nowplaying = {
        file = ./secrets/cloudflared-nowplaying-credentials.age;
        kind = "credential";
        trusted = true;
        consumers = [ "cloudflared-tunnel-mouse-3" ];
      };
    };
  };
}
