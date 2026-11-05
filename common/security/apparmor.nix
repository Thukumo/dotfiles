{
  config,
  lib,
  pkgs,
  ...
}:
let
  cloudflared = config.services.cloudflared;
  closureRules = pkgs.apparmorRulesFromClosure { name = "cloudflared"; } [
    cloudflared.package
  ];
  tunnelRules = lib.concatMapStrings (name: ''
    "/run/credentials/cloudflared-tunnel-${name}.service/**" r,
    "/run/cloudflared-tunnel-${name}/**" rw,
  '') (builtins.attrNames cloudflared.tunnels);
in
{
  # AppArmor is enabled everywhere, but policies are added incrementally.
  # cloudflared starts in complain mode; enforce it after reviewing the logs.
  security.apparmor = {
    enable = true;
    killUnconfinedConfinables = false;

    policies = lib.optionalAttrs cloudflared.enable {
      cloudflared = {
        state = "complain";
        profile = ''
          abi <abi/5.0>,

          include <tunables/global>

          profile cloudflared ${cloudflared.package}/bin/cloudflared {
            include <abstractions/base>
            include <abstractions/nameservice>
            include <abstractions/ssl_certs>
            include "${closureRules}"

            ${tunnelRules}
            "/nix/store/*-cloudflared.yml" r,
            "/etc/machine-id" r,
          }
        '';
      };
    };
  };
}
