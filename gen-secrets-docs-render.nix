# SECRETS.md のレンダリング本体。flake の genSecretsDocs 出力から評価される:
#   nix eval --raw --apply 'x: x.render x.hostsData' .#genSecretsDocs
{ lib, self }:
hostsData:

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

  empty = "—";

  sanitize = s: lib.replaceStrings [ "\r\n" "\r" "\n" ] [ " " " " " " ] (toString s);

  fenceFor =
    s:
    let
      go =
        n:
        let
          fence = lib.concatStrings (builtins.genList (_: "`") n);
        in
        if lib.hasInfix fence s then go (n + 1) else fence;
    in
    go 1;

  codeSpan =
    s:
    let
      text = sanitize s;
      fence = fenceFor text;
      pad =
        if
          lib.hasPrefix "`" text || lib.hasSuffix "`" text || lib.hasPrefix " " text || lib.hasSuffix " " text
        then
          " "
        else
          "";
    in
    "${fence}${pad}${text}${pad}${fence}";

  # 表の区切り文字より先に pipe をエスケープする
  cellCode = s: codeSpan (lib.replaceStrings [ "|" ] [ "\\|" ] (sanitize s));

  listCell =
    values:
    let
      sorted = lib.sort (a: b: a < b) values;
    in
    if sorted == [ ] then empty else lib.concatMapStringsSep ", " cellCode sorted;

  kindCell = entry: if (entry.kind or null) == null then empty else cellCode entry.kind;

  pathCell = value: if value == null then empty else cellCode value;

  principal = value: if value == "0" then "root" else toString value;

  ownerGroup =
    entry:
    let
      owner = entry.owner or null;
      group = entry.group or null;
    in
    if owner == null && group == null then
      empty
    else
      cellCode "${if owner == null then empty else principal owner}:${
        if group == null then empty else principal group
      }";

  trustCell =
    entry:
    if entry.trusted or false then
      "trusted"
    else if (entry.acceptedRisk or null) != null then
      "accepted risk: ${cellCode entry.acceptedRisk}"
    else
      "**unmarked**";

  table =
    headers: rows:
    let
      line = cells: "| " + lib.concatStringsSep " | " cells + " |";
    in
    lib.concatStringsSep "\n" (
      [
        (line headers)
        (line (map (_: "---") headers))
      ]
      ++ map line rows
    );

  sortedEntries =
    attrs:
    lib.sort (a: b: a.name < b.name) (lib.mapAttrsToList (name: entry: { inherit name entry; }) attrs);

  systemRow =
    item:
    let
      e = item.entry;
    in
    [
      (cellCode item.name)
      (kindCell e)
      (cellCode (rel e.file))
      (pathCell (e.path or null))
      (ownerGroup e)
      (listCell (e.consumers or [ ]))
      (listCell (e.programs or [ ]))
      (trustCell e)
    ];

  homeRow =
    item:
    let
      e = item.entry;
    in
    [
      (cellCode item.name)
      (cellCode (rel e.file))
      (cellCode (e.runtime or "$XDG_RUNTIME_DIR/agenix/${item.name}"))
      (pathCell (e.path or null))
      (listCell (e.consumers or [ ]))
      (listCell (e.programs or [ ]))
      (trustCell e)
    ];

  renderHomeUser =
    userName: entries:
    "### Home secrets (${codeSpan userName})\n\n"
    + table [
      "Secret"
      "File"
      "Runtime"
      "Home path"
      "Consumers"
      "Programs"
      "Trust"
    ] (map homeRow entries);

  renderHost =
    hostName: data:
    let
      systemEntries = sortedEntries (data.system or { });
      homeUsers = lib.sort (a: b: a < b) (lib.attrNames (data.home or { }));
      homeSections = lib.concatMap (
        userName:
        let
          entries = sortedEntries (data.home.${userName} or { });
        in
        lib.optional (entries != [ ]) (renderHomeUser userName entries)
      ) homeUsers;

      systemSection =
        if systemEntries == [ ] then
          "### System secrets\n\nNo system secrets."
        else
          "### System secrets\n\n"
          + table [
            "Secret"
            "Kind"
            "File"
            "Runtime"
            "Owner:Group"
            "Consumers"
            "Programs"
            "Trust"
          ] (map systemRow systemEntries);

      homeSection =
        if homeSections == [ ] then
          "### Home secrets\n\nNo home secrets."
        else
          lib.concatStringsSep "\n\n" homeSections;
    in
    "## ${hostName}\n\n${systemSection}\n\n${homeSection}";

  hosts = lib.sort (a: b: a < b) (lib.attrNames hostsData);
  hostSections = map (hostName: renderHost hostName hostsData.${hostName}) hosts;

  preamble = ''
    # Secrets Access Matrix
    Generated on __DATE_PLACEHOLDER__

    > **GENERATED FILE** - do not edit manually.
    > Regenerate with `pre-commit run gen-docs --all-files`.

    ## Legend

    - Decrypted secrets are mode `0400`.
    - System secrets are exposed at the runtime path shown.
    - Home secrets are exposed at the runtime path shown; `Home path` is the optional symlink relative to the user's home (`—` means no symlink).
  '';

  body = lib.concatStringsSep "\n\n" hostSections;
in
preamble + lib.optionalString (body != "") ("\n" + body + "\n")
