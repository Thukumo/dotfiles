#!/usr/bin/env bash

echo "Generating CUSTOM_OPTIONS.md in tree format..."

# Nix側で直接Markdownを組み立てるためのスクリプトを生成
cat << 'EOF' > /tmp/gen-docs.nix
let
  lib = (import <nixpkgs> {}).lib;
  
  # 再帰的に木構造をMarkdown化する関数
  renderTree = indent: name: opt:
    let
      isOption = opt ? _type && opt._type == "option";
      # プレフィックスの空白
      p = lib.concatStrings (builtins.genList (x: "  ") indent);
    in
    if isOption then
      let
        desc = if opt ? description then 
                 (if builtins.isString opt.description then opt.description else "Complex description")
               else "No description";
        default = if opt ? default then builtins.toJSON opt.default else "No default";
      in
      "${p}- `${name}` (Default: `${default}`): ${desc}
"
    else if builtins.isAttrs opt && !(opt ? _type) then
      let
        # 子要素を再帰的に取得
        renderedChildren = lib.mapAttrsToList (n: v: renderTree (indent + 1) n v) opt;
        content = lib.concatStrings renderedChildren;
      in
      if content == "" then "" else "${p}- **${name}**
${content}"
    else
      "";

in
opt: "# Custom Options Tree
Generated on ${builtins.substring 0 10 (builtins.toString builtins.currentTime)}

" + (renderTree 0 "custom" opt)
EOF

nix eval .#nixosConfigurations.thinkpadx13-nix.options.custom --impure --raw --apply "$(cat /tmp/gen-docs.nix)" > CUSTOM_OPTIONS.md

rm /tmp/gen-docs.nix
echo "Done! Check CUSTOM_OPTIONS.md"
