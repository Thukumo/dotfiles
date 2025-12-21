{ pkgs, osConfig, config, ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = config.home.username; # or osConfig.users.users.${config.home.username}.name (which is redundant)
        email = osConfig.users.users.${config.home.username}.custom.email;
      };
    };
  };
  programs.gh = {
    enable = true;
  };
  programs.lazygit = {
    enable = true;
    settings = { };
  };
}
