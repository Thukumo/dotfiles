{
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
      core = {
        editor = "nvim";
      };
    };
  };
  programs.gh = {
    enable = true;
    settings = {
      editor = "nvim";
    };
  };
  programs.lazygit = {
    enable = true;
    settings = {
      disableStartupPopups = true;
    };
  };
}
