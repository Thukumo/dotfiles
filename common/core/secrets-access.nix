{
  config,
  lib,
  options,
  ...
}:
let
  cfg = config.custom.secrets.access;

  commonOptions = {
    file = lib.mkOption {
      type = lib.types.path;
      description = "Encrypted age file.";
    };

    path = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Decrypted path override; null uses the agenix default.";
    };

    consumers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Units that consume the secret.";
    };

    trusted = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether the consumer is intentionally trusted to read this secret.";
    };

    acceptedRisk = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Reason this secret is intentionally not isolated; home secrets are user-level.";
    };
  };

  systemType = lib.types.submodule {
    options = commonOptions // {
      kind = lib.mkOption {
        type = lib.types.enum [
          "root"
          "credential"
          "owner"
        ];
        description = "How the secret is delivered and who may read it.";
      };

      owner = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Owner override; null uses the agenix default.";
      };

      group = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Group override; null uses the agenix default.";
      };
    };
  };

  homeType = lib.types.submodule {
    options = commonOptions;
  };

  mode0400 =
    mode:
    builtins.elem mode [
      "0400"
      "400"
    ];
  rootName =
    name:
    builtins.elem name [
      "0"
      "root"
    ];
  knownUser = name: rootName name || builtins.hasAttr name config.users.users;
  knownGroup = name: rootName name || builtins.hasAttr name config.users.groups;

  hasHomeManager = options ? home-manager;
  customUserNames = if config ? custom.users then builtins.attrNames config.custom.users else [ ];

  generatedSystemSecrets = lib.mapAttrs (
    _name: secret:
    {
      inherit (secret) file;
    }
    // lib.optionalAttrs (secret.path != null) { inherit (secret) path; }
    // lib.optionalAttrs (secret.owner != null) { inherit (secret) owner; }
    // lib.optionalAttrs (secret.group != null) { inherit (secret) group; }
  ) cfg.system;

  generatedHomeSecrets = lib.mapAttrs (_: entries: {
    age.secrets = lib.mapAttrs (
      _name: secret:
      {
        inherit (secret) file;
      }
      // lib.optionalAttrs (secret.path != null) { inherit (secret) path; }
    ) entries;
  }) cfg.home;

  systemSecrets = config.age.secrets;
  systemAccess = cfg.system;
  systemNames = builtins.attrNames systemSecrets;
  missingSystem = builtins.filter (name: !(builtins.hasAttr name systemAccess)) systemNames;
  homeUsersKnown = builtins.filter (name: !(builtins.elem name customUserNames)) (
    builtins.attrNames cfg.home
  );

  systemAssertions = lib.concatMap (
    name:
    if !(builtins.hasAttr name systemAccess) then
      [ ]
    else
      let
        secret = systemSecrets.${name};
        access = systemAccess.${name};
        unitExists = unit: builtins.hasAttr unit config.systemd.services;
        hasCredential =
          unit:
          if !(unitExists unit) then
            false
          else
            let
              service = config.systemd.services.${unit};
              value = service.serviceConfig.LoadCredential or [ ];
              credentials = builtins.filter builtins.isString (
                if builtins.isList value then value else [ value ]
              );
            in
            lib.any (credential: lib.hasSuffix ":${secret.path}" credential) credentials;
      in
      [
        {
          assertion = mode0400 secret.mode;
          message = "custom.secrets.access.system.${name}: mode must be 0400";
        }
        {
          assertion = if access.kind == "owner" then !(rootName secret.owner) else rootName secret.owner;
          message = "custom.secrets.access.system.${name}: owner is inconsistent with kind ${access.kind}";
        }
        {
          assertion = access.trusted || access.acceptedRisk != null;
          message = "custom.secrets.access.system.${name}: mark trusted or acceptedRisk";
        }
        {
          assertion = knownUser secret.owner;
          message = "custom.secrets.access.system.${name}: owner ${secret.owner} does not exist";
        }
        {
          assertion = knownGroup secret.group;
          message = "custom.secrets.access.system.${name}: group ${secret.group} does not exist";
        }
        {
          assertion = lib.all unitExists access.consumers;
          message = "custom.secrets.access.system.${name}: consumers must exist: ${lib.concatStringsSep ", " access.consumers}";
        }
        {
          assertion =
            access.kind != "credential" || (access.consumers != [ ] && lib.all hasCredential access.consumers);
          message = "custom.secrets.access.system.${name}: credential consumers must have LoadCredential for ${secret.path}";
        }
        {
          assertion = access.kind != "root" || access.consumers == [ ];
          message = "custom.secrets.access.system.${name}: root secrets must not declare consumers";
        }
      ]
  ) systemNames;

  homeAssertions =
    if !hasHomeManager then
      [ ]
    else
      lib.concatLists (
        lib.mapAttrsToList (
          userName: hm:
          let
            secrets = hm.age.secrets;
            access = cfg.home.${userName} or { };
            names = builtins.attrNames secrets;
            missing = builtins.filter (name: !(builtins.hasAttr name access)) names;
            homeUnits =
              builtins.attrNames (hm.systemd.user.services or { })
              ++ map (v: v.quadletData.serviceName) (
                builtins.attrValues (hm.services.podman.internal.builtQuadlets or { })
              );
          in
          [
            {
              assertion = missing == [ ];
              message = "custom.secrets.access.home.${userName}: missing metadata for ${lib.concatStringsSep ", " missing}";
            }
          ]
          ++ lib.concatMap (
            name:
            if !(builtins.hasAttr name access) then
              [ ]
            else
              let
                secret = secrets.${name};
                a = access.${name};
              in
              [
                {
                  assertion = mode0400 secret.mode;
                  message = "custom.secrets.access.home.${userName}.${name}: mode must be 0400";
                }
                {
                  assertion = a.trusted || a.acceptedRisk != null;
                  message = "custom.secrets.access.home.${userName}.${name}: mark trusted or acceptedRisk";
                }
                {
                  assertion = lib.all (unit: builtins.elem unit homeUnits) a.consumers;
                  message = "custom.secrets.access.home.${userName}.${name}: consumers must exist: ${lib.concatStringsSep ", " a.consumers}";
                }
              ]
          ) names
        ) config.home-manager.users
      );
in
{
  options.custom.secrets.access = {
    system = lib.mkOption {
      type = lib.types.attrsOf systemType;
      default = { };
      description = "System secret definitions and access metadata.";
    };

    home = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf homeType);
      default = { };
      description = "Home-manager secret definitions and access metadata, keyed by user.";
    };

    report = lib.mkOption {
      type = lib.types.attrs;
      readOnly = true;
      internal = true;
      default = lib.mapAttrs (name: secret: {
        inherit (secret) mode owner group;
        inherit (systemAccess.${name})
          kind
          file
          path
          consumers
          trusted
          acceptedRisk
          ;
      }) (lib.filterAttrs (name: _: builtins.hasAttr name systemAccess) systemSecrets);
      description = "Read-only access matrix for system secrets on this host.";
    };
  };

  config = {
    age.secrets = generatedSystemSecrets;
    assertions = [
      {
        assertion = missingSystem == [ ];
        message = "custom.secrets.access.system: missing metadata for ${lib.concatStringsSep ", " missingSystem}";
      }
      {
        assertion = homeUsersKnown == [ ];
        message = "custom.secrets.access.home: unknown users: ${lib.concatStringsSep ", " homeUsersKnown}";
      }
      {
        assertion = builtins.attrNames cfg.home == [ ] || hasHomeManager;
        message = "custom.secrets.access.home requires home-manager";
      }
    ]
    ++ systemAssertions
    ++ homeAssertions;
  }
  // lib.optionalAttrs hasHomeManager {
    home-manager.users = generatedHomeSecrets;
  };
}
