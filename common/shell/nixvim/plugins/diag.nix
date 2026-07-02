_:

{
  programs.nixvim.plugins = {
    trouble.enable = true;
    tiny-inline-diagnostic = {
      enable = true;
      settings.preset = "modern";
    };
  };
}
