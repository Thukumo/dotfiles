{
  lib,
  config,
  pkgs,
  myLib,
  ...
}:
let
  cfgLuks = config.custom.hardware.disk.disko.luks;
  cryptsetupUnit = "systemd-cryptsetup@${cfgLuks.deviceName}.service";

  # Garbage collection for /persist.
  #
  # The root subvolume is rolled back on every boot, so data of persistence
  # entries that were dropped from the configuration should not linger in
  # /persist either. Everything that is not declared (see `declaredPaths`)
  # is deleted at boot.
  #
  # Kept path semantics:
  #   - a declared file/directory itself (whole subtree: declaring a
  #     directory persists everything inside it),
  #   - every ancestor of a declared path, so shared parent directories
  #     survive (their undeclared siblings are still removed).
  persistRoot = "/persist";
  gcCfg = config.custom.impermanence.gc;

  # impermanence stores paths as <persistentStoragePath><home dir><entry>
  # (mirrors concatPaths from impermanence's submodule-options.nix).
  concatPaths =
    parts:
    let
      joined = lib.concatStringsSep "/" (
        lib.filter (s: s != "") (lib.concatMap (lib.splitString "/") parts)
      );
    in
    (lib.optionalString (lib.hasPrefix "/" (builtins.head parts)) "/") + joined;

  # Keep paths are used as find(1) patterns. Normalize them first: a trailing
  # slash or a relative path would pass the old prefix assertion but never
  # match, letting find delete the data it was supposed to keep.
  hasDotComponent = p: lib.any (part: part == "." || part == "..") (lib.splitString "/" p);

  normalizePersistPath =
    p:
    let
      normalized = concatPaths [ p ];
    in
    if !(lib.hasPrefix "/" p) then
      throw "custom.impermanence: path '${p}' must be absolute"
    else if hasDotComponent p then
      throw "custom.impermanence: path '${p}' must not contain '.' or '..'"
    else
      normalized;

  entryPath =
    root: home: entry:
    concatPaths [
      root
      home
      (if builtins.isString entry then entry else entry.directory or entry.file)
    ];

  persistenceStores = lib.filter (s: s.enable) (lib.attrValues config.environment.persistence);

  systemEntryPaths = lib.concatLists (
    map (
      store:
      map (entryPath (store.persistentStoragePath or persistRoot) "/") (store.directories ++ store.files)
    ) persistenceStores
  );

  userEntryPaths = lib.concatLists (
    map (
      store:
      lib.concatLists (
        lib.mapAttrsToList (
          name: user:
          map (entryPath (store.persistentStoragePath or persistRoot) config.users.users.${name}.home) (
            user.directories ++ user.files
          )
        ) store.users
      )
    ) persistenceStores
  );

  homeEntryPaths = lib.concatLists (
    lib.mapAttrsToList (
      _: hm:
      let
        persist = hm.home.persistence.${persistRoot} or null;
      in
      lib.optionals (persist != null && persist.enable) (
        map (entryPath (persist.persistentStoragePath or persistRoot) hm.home.homeDirectory) (
          persist.directories ++ persist.files
        )
      )
    ) config.home-manager.users
  );

  allPersistencePaths = systemEntryPaths ++ userEntryPaths ++ homeEntryPaths;

  # A path that resolves to /persist itself is dropped by the strict-child
  # filter below. If that happens, fail instead of silently not protecting it.
  rootPersistencePaths = lib.filter (p: p == persistRoot) allPersistencePaths;

  # find(1) does not resolve '.' or '..'; such a path would pass the prefix
  # check but not protect the real target.
  unsafePersistencePaths = lib.filter (
    p: lib.hasPrefix persistRoot p && hasDotComponent p
  ) allPersistencePaths;

  persistencePaths = lib.unique (
    lib.filter (p: lib.hasPrefix "${persistRoot}/" p) allPersistencePaths
  );

  # Modules that write directly into /persist (e.g. ssh host keys)
  # append their paths to custom.impermanence.gc.keep.
  normalizedKeep = map normalizePersistPath (lib.optionals gcCfg.enable gcCfg.keep);

  # Small self-check for the normalization used by find(1) patterns.
  _pathNormalizationCheck =
    assert normalizePersistPath "${persistRoot}/foo/" == "${persistRoot}/foo";
    assert normalizePersistPath "${persistRoot}//foo" == "${persistRoot}/foo";
    assert !(builtins.tryEval (normalizePersistPath "${persistRoot}/../etc")).success;
    assert !(builtins.tryEval (normalizePersistPath "etc/foo")).success;
    true;

  declaredPaths =
    assert _pathNormalizationCheck;
    lib.unique (persistencePaths ++ normalizedKeep);

  # All ancestors of the declared paths, including the paths themselves.
  parentsOf =
    path:
    let
      prefix = lib.optionalString (lib.hasPrefix "/" path) "/";
      parts = lib.filter (s: s != "") (lib.splitString "/" path);
    in
    lib.genList (i: prefix + lib.concatStringsSep "/" (lib.take (i + 1) parts)) (lib.length parts);

  ancestorPaths = lib.filter (p: p != persistRoot && !builtins.elem p declaredPaths) (
    lib.unique (lib.concatMap parentsOf declaredPaths)
  );

  # find's -path uses fnmatch, escape glob metacharacters in configured paths.
  escapeGlob = lib.replaceStrings [ "\\" "*" "?" "[" "]" ] [ "\\\\" "\\*" "\\?" "\\[" "\\]" ];

  pathArgs =
    paths: lib.concatStringsSep " -o " (map (p: "-path ${lib.escapeShellArg (escapeGlob p)}") paths);

  # Escape the parentheses: the expression is embedded in a bash array, where
  # unquoted ( and ) would be a syntax error.
  pathExpr =
    paths: if paths == [ ] then "-false" else "\\( ${pathArgs (lib.sort (a: b: a < b) paths)} \\)";

  gcScript = pkgs.writeShellApplication {
    name = "impermanence-gc";
    runtimeInputs = with pkgs; [
      coreutils
      findutils
      util-linux
    ];
    text = ''
      usage() {
        echo "usage: impermanence-gc [--dry-run]" >&2
      }

      dry_run=0
      case "''${1:-}" in
        --dry-run) dry_run=1 ;;
        "") ;;
        *)
          usage
          exit 2
          ;;
      esac

      if ! mountpoint -q ${persistRoot}; then
        echo "impermanence-gc: ${persistRoot} is not a mount point, skipping" >&2
        exit 0
      fi

      args=(
        ${persistRoot}
        -xdev
        -mindepth 1
        ${pathExpr declaredPaths}
        -prune
        -o
        ${pathExpr ancestorPaths}
        -o
      )

      if (( dry_run )); then
        find "''${args[@]}" -print -prune
      else
        find "''${args[@]}" -print -prune -exec rm -rf --one-file-system -- {} +
      fi
    '';
  };
in

{
  options.custom.impermanence.gc = {
    enable = myLib.mkEnabledOption "removal of data in ${persistRoot} that is no longer declared as persistent";
    keep = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "${persistRoot}/var/lib/my-manual-state" ];
      description = ''
        Paths below ${persistRoot} kept even when they are not declared via
        `environment.persistence` or `home.persistence`. Modules that write
        directly into ${persistRoot} should append their paths here.
        To keep everything, disable `custom.impermanence.gc` instead.
      '';
    };
  };

  config = {
    environment.persistence."/persist" = {
      hideMounts = true;
      directories = [
        "/var/lib/bluetooth"
        "/var/lib/systemd/backlight"
        "/var/lib/systemd/timers"
        "/var/lib/nixos"
        "/var/log"
        "/var/lib/systemd/pstore"
      ];
      files = [ "/etc/machine-id" ];
    };

    home-manager.users = myLib.mkForEachUsers config (_: true) (user: {
      home.persistence."/persist" = {
        directories = user.custom.persistence.directories or [ ];
        files = user.custom.persistence.files or [ ];
      };
    });
    assertions = [
      {
        # Do not count the built-in persistence entries or gc.keep here: those
        # are always present, so they would hide a broken user/home collection
        # and let the GC delete everything else.
        assertion = !gcCfg.enable || persistencePaths != [ ];
        message = ''
          custom.impermanence.gc: no user/system persistence paths were collected
          from the configuration; refusing to run, as that would delete all of
          ${persistRoot}.
        '';
      }
      {
        assertion = !gcCfg.enable || rootPersistencePaths == [ ];
        message = ''
          custom.impermanence.gc: a persistence entry resolves to ${persistRoot}
          itself. Declare a strict child instead; GC cannot protect the root.
        '';
      }
      {
        assertion = !gcCfg.enable || unsafePersistencePaths == [ ];
        message = ''
          custom.impermanence.gc: persistence paths below ${persistRoot} must
          not contain '.' or '..': ${lib.concatStringsSep ", " unsafePersistencePaths}
        '';
      }
      {
        assertion =
          !gcCfg.enable || lib.all (p: p != persistRoot && lib.hasPrefix "${persistRoot}/" p) normalizedKeep;
        message = ''
          custom.impermanence.gc.keep entries must be absolute strict children of
          ${persistRoot}, without trailing slashes, '.' or '..'.
          To keep all of ${persistRoot}, disable custom.impermanence.gc instead.
        '';
      }
    ];

    systemd.services.impermanence-gc = lib.mkIf gcCfg.enable {
      description = "Remove undeclared data from ${persistRoot}";
      wantedBy = [ "sysinit.target" ];
      before = [ "sysinit.target" ];
      after = [ "local-fs.target" ];
      # DefaultDependencies would add After=sysinit.target, contradicting the
      # ordering above (the service must run before user services start).
      unitConfig.DefaultDependencies = false;
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${gcScript}/bin/impermanence-gc";
      };
    };

    environment.systemPackages = lib.mkIf gcCfg.enable [ gcScript ];

    # Trashの削除
    systemd.tmpfiles.rules =
      lib.flatten (
        lib.mapAttrsToList (
          name: user:
          let
            dirPaths = builtins.map (dir: if builtins.isString dir then dir else dir.directory) (
              config.home-manager.users."${name}".home.persistence."/persist".directories or [ ]
            );
          in
          builtins.map (dir: "R! /persist${user.home}/${dir}/.Trash-* - - - -") dirPaths
        ) (lib.filterAttrs (_: user: user.isNormalUser) config.users.users)
      )
      ++ [
        "z /var/lib/private 0700 root root -"
        "d /var/lib/private 0700 root root -"
      ];

    boot.initrd.systemd.services.rollback = lib.mkIf config.custom.hardware.disk.disko.enable {
      description = "Rollback Btrfs root subvolume";
      wantedBy = [ "initrd.target" ];
      after = [
        "dev-vg-root.device"
        "systemd-hibernate-resume.service"
      ]
      ++ lib.optionals cfgLuks.enable [ cryptsetupUnit ];
      wants = lib.mkIf cfgLuks.enable [ cryptsetupUnit ];
      before = [ "sysroot.mount" ];
      conflicts = [ "initrd-switch-root.target" ];
      unitConfig.DefaultDependencies = "no";
      serviceConfig.Type = "oneshot";
      script = ''
        mkdir -p /mnt
        mount -t btrfs -o subvolid=5 /dev/vg/root /mnt

        if [ -e /mnt/backup ]; then
          btrfs subvolume delete -R /mnt/backup
        fi

        if [ -e /mnt/root ]; then
          mv /mnt/root /mnt/backup
        fi

        btrfs subvolume create /mnt/root

        umount /mnt
      '';
    };
  };
}
