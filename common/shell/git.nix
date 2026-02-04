{
  pkgs,
  myConfig,
  config,
  lib,
  ...
}:

{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = config.home.username;
        email = lib.mkDefault (myConfig.email or "${config.home.username}@localhost");
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
