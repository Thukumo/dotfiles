{
  lib,
  myConfig,
  ...
}:
let
  isEnabled = myConfig.account.shell == "fish";
in
{
  programs.fish = {
    enable = isEnabled;
    interactiveShellInit = ''
      if type -q gh
        set -gx NIX_CONFIG "access-tokens = github.com=\$(gh auth token 2>/dev/null)"
      end
    '';
  };
  home.persistence."/persist".directories = lib.optionals isEnabled [
    ".local/share/fish"
  ];
}
