{
  pkgs,
  lib,
  osConfig,
  config,
  ...
}:
let
  isEnabled = osConfig.users.users.${config.home.username}.shell == pkgs.fish;
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
