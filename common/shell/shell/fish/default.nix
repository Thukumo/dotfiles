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
  };
  home.persistence."/persist".directories = lib.optionals isEnabled [
    ".local/share/fish"
  ];
}
