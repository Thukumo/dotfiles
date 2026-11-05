{
  config,
  lib,
  pkgs,
  ...
}:
let
  access = config.custom.secrets.access;

  # AppArmor profiles are generated from custom.secrets.access.*.programs.
  # Programs that are not useful/safe to confine are listed with an explicit
  # reason; an unknown program name is a build error.
  programSpecs = {
    cloudflared = {
      package = config.services.cloudflared.package;
      executable = "bin/cloudflared";
      abstractions = [
        "nameservice"
        "ssl_certs"
      ];
      extraRules = ''
        ${lib.concatMapStrings (name: ''
          "/run/credentials/cloudflared-tunnel-${name}.service/**" r,
          "/run/cloudflared-tunnel-${name}/**" rw,
        '') (builtins.attrNames config.services.cloudflared.tunnels)}
        "/nix/store/*-cloudflared.yml" r,
        "/etc/machine-id" r,
        "/proc/*/cgroup" r,
        "/proc/*/mountinfo" r,
        "/sys/fs/cgroup/**" r,
        "/run/bpftune/**" r,
        "/proc/sys/net/ipv4/ping_group_range" r,
        "/run/nscd/socket" rw,
      '';
    };

    wpa_supplicant = {
      package = pkgs.wpa_supplicant;
      executable = "bin/wpa_supplicant";
      abstractions = [ "dbus-strict" ];
      extraRules = ''
        "/run/wpa_supplicant/**" rw,
        "/etc/wpa_supplicant/**" r,
      '';
    };

    ssh = {
      skip = "interactive user program; same-user isolation is weak";
    };
    ssh-keygen = {
      skip = "interactive user program; same-user isolation is weak";
    };
    gh = {
      skip = "interactive user program; wrapper script";
    };
    nix = {
      skip = "interactive user program; broad store access";
    };
    opencode = {
      skip = "intentionally unsandboxed";
    };
    nowplaying-client = {
      skip = "token is delivered by systemd EnvironmentFile";
    };
    podman = {
      skip = "container runtime; container-level policy is separate";
    };
    vpn-sstp-connect = {
      skip = "generated script; uses sudo and sstpc";
    };
  };

  programNames = lib.unique (
    lib.concatMap (secret: secret.programs) (lib.attrValues access.system)
    ++ lib.concatMap (entries: lib.concatMap (secret: secret.programs) (lib.attrValues entries)) (
      lib.attrValues access.home
    )
  );

  unknownPrograms = lib.filter (name: !(builtins.hasAttr name programSpecs)) programNames;
  profiledPrograms = lib.filter (
    name: builtins.hasAttr name programSpecs && !(builtins.hasAttr "skip" programSpecs.${name})
  ) programNames;

  systemAssociations = lib.concatLists (
    lib.mapAttrsToList (
      name: secret:
      map (program: {
        inherit program;
        path = config.age.secrets.${name}.path;
      }) secret.programs
    ) access.system
  );

  homeAssociations = lib.concatLists (
    lib.mapAttrsToList (
      _user: entries:
      lib.concatLists (
        lib.mapAttrsToList (
          name: secret:
          map (program: {
            inherit program;
            path = "/run/user/*/agenix/${name}";
          }) secret.programs
        ) entries
      )
    ) access.home
  );

  associations = systemAssociations ++ homeAssociations;
  pathsFor =
    program:
    lib.unique (
      map (entry: entry.path) (builtins.filter (entry: entry.program == program) associations)
    );

  makeProfile =
    name: spec:
    let
      executable = "${spec.package}/${spec.executable}";
      closureRules = pkgs.apparmorRulesFromClosure { inherit name; } [ spec.package ];
      abstractions = lib.concatMapStrings (abstraction: "include <abstractions/${abstraction}>\n") (
        [ "base" ] ++ (spec.abstractions or [ ])
      );
      secretRules = lib.concatMapStrings (path: "\"${path}\" r,\n") (pathsFor name);
    in
    ''
      abi <abi/5.0>,

      include <tunables/global>

      profile ${name} ${executable} {
        ${abstractions}
        include "${closureRules}"
        "${executable}" mr,
        ${secretRules}
        ${spec.extraRules or ""}
      }
    '';

  policies = lib.listToAttrs (
    map (name: {
      inherit name;
      value = {
        state = "complain";
        profile = makeProfile name programSpecs.${name};
      };
    }) profiledPrograms
  );
in
{
  security.apparmor = {
    enable = true;
    killUnconfinedConfinables = false;
    inherit policies;
  };

  assertions = [
    {
      assertion = unknownPrograms == [ ];
      message = "custom.security.apparmor: no program spec for ${lib.concatStringsSep ", " unknownPrograms}";
    }
  ];
}
