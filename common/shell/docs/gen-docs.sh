#!/usr/bin/env bash

echo "Generating CUSTOM_OPTIONS.md in tree format (generalized filtering)..."

# Nix側で直接Markdownを組み立てるためのスクリプトを生成
cat << 'EOF' > /tmp/gen-docs.nix
let
  lib = (import <nixpkgs> {}).lib;
  
  # 文字列のクリーンアップ
  cleanDesc = s: 
    if !builtins.isString s then "No description"
    else lib.replaceStrings ["\n" "\r" "`" "|"] [" " "" "'" "/"] s;

  # 再帰的に木構造をMarkdown化する関数
  renderTree = indent: name: opt:
    let
      isOption = opt ? _type && opt._type == "option";
      
      # サブモジュールの判定
      isSubmodule = isOption && (opt.type.name or "") == "submodule";
      # attrsOf (submodule) の判定
      isAttrsOfSubmodule = isOption && (lib.hasPrefix "attribute set of (submodule)" (opt.type.description or ""));

      # プレフィックスの空白
      p = lib.concatStrings (builtins.genList (x: "  ") indent);
    in
    if isSubmodule then
      let
        # サブモジュールのオプションを取得
        subOpts = opt.type.getSubOptions [];
        # _ で始まる内部属性を除外
        filteredSubOpts = lib.filterAttrs (n: _: ! (lib.hasPrefix "_" n)) subOpts;
        children = lib.mapAttrsToList (n: v: renderTree (indent + 1) n v) filteredSubOpts;
        content = lib.concatStrings children;
      in
      if content == "" then "" else "${p}- **${name}** (Submodule)\n${content}"
    else if isAttrsOfSubmodule then
      let
        # attrsOf submodule の場合、入れ子の型からオプションを取得
        subOpts = if opt.type ? nestedTypes then opt.type.nestedTypes.elemType.getSubOptions [] else {};
        # _ で始まる内部属性を除外
        filteredSubOpts = lib.filterAttrs (n: _: ! (lib.hasPrefix "_" n)) subOpts;
        children = lib.mapAttrsToList (n: v: renderTree (indent + 1) n v) filteredSubOpts;
        content = lib.concatStrings children;
      in
      if content == "" then "" else "${p}- **${name}** (User Options)\n${content}"
    else if isOption then
      let
        desc = if opt ? description then cleanDesc opt.description else "No description";
        default = if opt ? default then builtins.toJSON opt.default else "No default";
      in
      "${p}- `${name}` (Default: `${default}`): ${desc}\n"
    else if builtins.isAttrs opt && !(opt ? _type) then
      let
        # 子要素を再帰的に取得
        # 通常の属性セットでも _ で始まるものは除外
        filteredAttrs = lib.filterAttrs (n: _: ! (lib.hasPrefix "_" n)) opt;
        renderedChildren = lib.mapAttrsToList (n: v: renderTree (indent + 1) n v) filteredAttrs;
        content = lib.concatStrings renderedChildren;
      in
      if content == "" then "" else "${p}- **${name}**\n${content}"
    else
      "";

in
opt: "# Custom Options Tree\nGenerated on __DATE_PLACEHOLDER__\n\n" + (renderTree 0 "custom" opt)
EOF

nix eval .#nixosConfigurations.thinkpadx13-nix.options.custom --impure --raw --apply "$(cat /tmp/gen-docs.nix)" > CUSTOM_OPTIONS.md

# 日付を人間に読みやすい形式に置換
sed -i "s/__DATE_PLACEHOLDER__/$(date '+%Y-%m-%d %H:%M:%S')/" CUSTOM_OPTIONS.md

rm /tmp/gen-docs.nix
echo "Done! Check CUSTOM_OPTIONS.md"
