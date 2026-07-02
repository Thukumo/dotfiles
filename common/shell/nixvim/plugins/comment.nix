_:

{
  programs.nixvim.plugins.comment = {
    enable = true;
    settings = {
      opleader.line = "gc";
      toggler.line = "gcc";
    };
  };
}
