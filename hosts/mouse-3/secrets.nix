{ config, lib, ... }:

let
  service = config.systemd.services.cloudflared-tunnel-mouse-3;
  credentialValue = service.serviceConfig.LoadCredential or [ ];
  credentials = builtins.filter builtins.isString (
    if builtins.isList credentialValue then credentialValue else [ credentialValue ]
  );
in
{
  age.secrets.cloudflared_nowplaying = {
    file = ./secrets/cloudflared-nowplaying-credentials.age;
  };

  assertions = [
    {
      assertion = lib.any (
        credential: lib.hasSuffix ":${config.age.secrets.cloudflared_nowplaying.path}" credential
      ) credentials;
      message = "cloudflared-tunnel-mouse-3 must load cloudflared_nowplaying via LoadCredential";
    }
  ];
}
