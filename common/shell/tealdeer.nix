{
  programs.tealdeer = {
    enable = true;
    settings = {
      updates = {
        auto_update = true;
      };
    };
  };

  home.persistence."/persist" = {
    directories = [
      ".cache/tealdeer"
    ];
  };
}
