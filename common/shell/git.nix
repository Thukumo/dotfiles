{ pkgs, ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Tsukumo";
        email = "contact@tsukumo.f5.si";
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
