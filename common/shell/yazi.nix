{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    fd
    ripgrep

  ];

  programs.yazi = {
    enable = true;
    settings = {
      mgr = {
        linemode = "mtime";
      };
      opener = {
        edit = [
          {
            run = ''nvim "$@"'';
            block = true;
          }
        ];
        play = [
          {
            run = ''${pkgs.vlc}/bin/vlc "$@"'';
          }
        ];
        image = [
          {
            run = ''${pkgs.feh}/bin/feh "$@"'';
          }
        ];
      };
      open = {
        prepend_rules = [
          {
            mime = "text/*";
            use = [ "edit" ];
          }
          {
            mime = "image/*";
            use = [ "image" ];
          }
          {
            mime = "audio/*";
            use = [ "play" ];
          }
          {
            mime = "video/*";
            use = [ "play" ];
          }
        ];
      };
    };
  };
}
