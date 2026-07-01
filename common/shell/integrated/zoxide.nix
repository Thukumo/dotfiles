_:

{
  home.persistence."/persist".directories = [
    ".local/share/zoxide"
  ];
  programs.zoxide = {
    enable = true;
    options = [
      "--cmd cd"
    ];
  };
}
