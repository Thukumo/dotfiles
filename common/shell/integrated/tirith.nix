{ pkgs, ... }:
let
  # home-manager の tirith モジュールに nushell 統合がない + tirith init は bash/zsh/fish のみ対応のため手書きフック。
  # 制限: nushell の pre_execution では実行を止められず警告表示のみ (bash/zsh のようなブロックは不可)。
  # --warn-only を付けて表示を BLOCKED ではなく DETECTED (…cannot block in preexec mode) にするのが正直な形。
  # なお tirith check に nu/nushell 用トークナイザは存在しない (unknown shell) ため、
  # nu固有構文 ([...] 等) は posix 解析で analysis_incomplete に倒れることがある。誤検知時は TIRITH=0 で回避。
  text = ''
    if (($nu.is-interactive) and (not ('_TIRITH_NU_LOADED' in $env))) {
        $env._TIRITH_NU_LOADED = true
        let existing = ($env.config.hooks.pre_execution? | default [])
        $env.config.hooks.pre_execution = ($existing | append {||
          let cmd = (commandline)
          if ($cmd | is-empty) { return }
          let first_word = ($cmd | split row ' ' | first)
          if ($first_word == "tirith") or ($first_word | str ends-with "/tirith") { return }
            
          try {
            let result = (with-env {_TIRITH_HOOK: "1"} { do { ${pkgs.tirith}/bin/tirith check --warn-only --non-interactive --interactive --shell posix -- $cmd } | complete })
            if $result.exit_code != 0 {
              print -e $result.stderr
            }
          } catch {}
        })
    }
  '';
in
{
  programs.tirith.enable = true;
  programs.nushell.extraConfig = ''
    source ${pkgs.writeText "hook.nu" text}
  '';
}
