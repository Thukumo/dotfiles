{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    # feh
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
            # run = ''${pkgs.vlc}/bin/vlc "$@"'';
            run = ''${pkgs.ffmpeg}/bin/ffplay -i "$@"'';
          }
        ];
      };
    };
  };
}
