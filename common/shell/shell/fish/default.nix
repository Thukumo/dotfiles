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
  };
  home.persistence."/persist".directories = lib.optionals isEnabled [
    ".local/share/fish"
  ];
}
