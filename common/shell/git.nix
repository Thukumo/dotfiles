{ pkgs, osConfig, config, lib, ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = config.home.username;
        email = lib.mkDefault (
          osConfig.users.users.${config.home.username}.custom.email 
          or "${config.home.username}@localhost"
        );
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
