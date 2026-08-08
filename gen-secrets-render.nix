# secrets.nix のレンダリング本体。flake の genSecrets 出力から評価される:
#   nix eval --raw --apply 'x: x.render x.hostsData x.keys' .#genSecrets
{ lib, self }:

let
  repoPrefix = toString self + "/";

  # flake ソースは /nix/store/...-source にコピーされるので、self を基準に相対化する
  rel =
    f:
    let
      s = toString f;
    in
    if lib.hasPrefix repoPrefix s then
      lib.removePrefix repoPrefix s
    else
      throw "secret file outside repo: ${s}";

  # user と host の組を "user@host" 文字列に正規化 (属性集合では == 比較ができないため)
  pair = r: "${r.user}@${r.host}";
in
hostsData: keys:
let
  systemRefs = lib.concatLists (
    lib.mapAttrsToList (
      hostName: data:
      map (f: {
        file = rel f;
        host = hostName;
        layer = "system";
      }) data.system
    ) hostsData
  );
  homeRefs = lib.concatLists (
    lib.mapAttrsToList (
      hostName: data:
      map (r: {
        file = rel r.file;
        host = hostName;
        inherit (r) user;
        layer = "home";
      }) data.home
    ) hostsData
  );

  allFiles = lib.sort (a: b: a < b) (lib.unique (map (r: r.file) (systemRefs ++ homeRefs)));

  # 秘密ごとの recipients を求める
  recipientsFor =
    file:
    let
      sysHosts = lib.sort (a: b: a < b) (
        lib.unique (map (r: r.host) (lib.filter (r: r.file == file && r.layer == "system") systemRefs))
      );
      homePairs = lib.sort (a: b: a < b) (
        lib.unique (map pair (lib.filter (r: r.file == file && r.layer == "home") homeRefs))
      );
      sysLookup =
        host:
        if keys.systemKeys ? "${host}" then
          "keys.systemKeys.\"${host}\""
        else
          throw "keys.nix: missing '${host}' in keys.systemKeys (required by ${file})";
      homeLookup =
        user: host:
        if keys.homeKeys ? "${user}" && keys.homeKeys.${user} ? "${host}" then
          "keys.homeKeys.\"${user}\".\"${host}\""
        else
          throw "keys.nix: missing '${user}.${host}' in keys.homeKeys (required by ${file}, referenced by ${user} on ${host})";
      sysKeys = map sysLookup sysHosts;
      homeKeys_ = map (
        p:
        let
          parts = lib.splitString "@" p;
          user = builtins.head parts;
          host = builtins.elemAt parts 1;
        in
        homeLookup user host
      ) homePairs;
      universalKeys = map sysLookup (keys.universalRecipients or [ ]);
      extraKeys = keys.extraRecipients.${file} or [ ];
      recipients = lib.unique (sysKeys ++ homeKeys_ ++ universalKeys ++ extraKeys);
    in
    {
      inherit recipients;
      refs = lib.sort (a: b: a < b) (lib.unique (sysHosts ++ homePairs));
    };

  # 警告: 未参照の .age ファイルと未使用のキー
  usedSystemHosts = lib.unique (map (r: r.host) systemRefs);
  usedHomePairs = lib.unique (map pair homeRefs);
  universalNames = keys.universalRecipients or [ ];
  unusedSystemKeys = lib.sort (a: b: a < b) (
    lib.filter (n: !(lib.elem n usedSystemHosts) && !(lib.elem n universalNames)) (
      lib.attrNames keys.systemKeys
    )
  );
  unusedHomeKeys = lib.sort (a: b: a < b) (
    lib.concatLists (
      lib.mapAttrsToList (
        user: hosts:
        lib.map (host: "${user}@${host}") (
          lib.filter (h: !(lib.elem "${user}@${h}" usedHomePairs)) (lib.attrNames hosts)
        )
      ) keys.homeKeys
    )
  );
  findAgeFiles =
    dir:
    lib.concatLists (
      lib.mapAttrsToList (
        name: type:
        if type == "directory" then
          findAgeFiles (toString dir + "/" + name)
        else
          lib.optional (lib.hasSuffix ".age" name) (rel (toString dir + "/" + name))
      ) (builtins.readDir dir)
    );
  orphans = lib.sort (a: b: a < b) (lib.filter (f: !(lib.elem f allFiles)) (findAgeFiles ./.));

  warnings =
    lib.concatMapStrings (f: "# WARNING: no host references ${f}\n") orphans
    + lib.concatMapStrings (n: "# WARNING: unused system key: ${n}\n") unusedSystemKeys
    + lib.concatMapStrings (n: "# WARNING: unused home key: ${n}\n") unusedHomeKeys;

  renderEntry =
    file:
    let
      e = recipientsFor file;
    in
    ''
      # ${file}
      #   referenced by: ${lib.concatStringsSep ", " e.refs}
      "${file}".publicKeys = [ ${lib.concatStringsSep " " e.recipients} ];
    '';
in
''
  # GENERATED FILE - do not edit manually.
  # Generated from keys.nix and the age.secrets declarations in the host configurations.
  # Regenerate with:
  #   nix eval --raw --apply 'x: x.render x.hostsData x.keys' .#genSecrets
  ${warnings}let
    keys = import ./keys.nix;
  in
  {
    ${lib.concatMapStringsSep "\n" renderEntry allFiles}
  }
''
