_:

{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
  };

  home.persistence."/persist".directories = [
    ".local/share/direnv"
  ];
}
