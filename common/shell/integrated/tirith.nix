{ pkgs, ... }:
let
  # todo
  # 止められません？
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
            let result = (with-env {_TIRITH_HOOK: "1"} { do { ${pkgs.tirith}/bin/tirith check --non-interactive --interactive --shell posix -- $cmd } | complete })
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
