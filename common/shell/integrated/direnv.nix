_:

{
  home.persistence."/persist".directories = [
    ".local/share/direnv"
  ];
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
