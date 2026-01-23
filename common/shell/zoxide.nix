{ ... }:

{
  programs.zoxide = {
    enable = true;
    options = [
      "--cmd cd"
    ];
  };
  home.persistence."/persist".directories = [
    ".local/share/zoxide"
  ];
}
