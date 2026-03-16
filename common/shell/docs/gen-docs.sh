#!/usr/bin/env bash

echo "Generating CUSTOM_OPTIONS.md in tree format (including submodules)..."

# Nix側で直接Markdownを組み立てるためのスクリプトを生成
cat << 'EOF' > /tmp/gen-docs.nix
let
  lib = (import <nixpkgs> {}).lib;
  
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
        children = lib.mapAttrsToList (n: v: renderTree (indent + 1) n v) opt;
        content = lib.concatStrings children;
      in
      if content == "" then "" else "${p}- **${name}** (Submodule)\n${content}"
    else if isAttrsOfSubmodule then
      let
        # attrsOf submodule の場合、入れ子の型からオプションを取得
        subOpts = if opt.type ? nestedTypes then opt.type.nestedTypes.elemType.getSubOptions [] else {};
        children = lib.mapAttrsToList (n: v: renderTree (indent + 1) n v) subOpts;
        content = lib.concatStrings children;
      in
      if content == "" then "" else "${p}- **${name}** (User Options)\n${content}"
    else if isOption then
      let
        desc = if opt ? description then 
                 (if builtins.isString opt.description then opt.description else "Complex description")
               else "No description";
        default = if opt ? default then builtins.toJSON opt.default else "No default";
      in
      "${p}- `${name}` (Default: `${default}`): ${desc}\n"
    else if builtins.isAttrs opt && !(opt ? _type) then
      let
        # 子要素を再帰的に取得
        renderedChildren = lib.mapAttrsToList (n: v: renderTree (indent + 1) n v) opt;
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
