{
  pkgs,
  osConfig,
  config,
  ...
}:

{
  programs.fish = {
    enable = osConfig.users.users.${config.home.username}.shell == pkgs.fish;
  };
}
