_:

{
  programs.nixvim.plugins = {
    telescope.enable = true;
    neo-tree.enable = true;

    lualine.enable = true;
    # bufferline.enable = true;
    mini-tabline.enable = true;

    web-devicons.enable = true;
    mini = {
      enable = true;
      mockDevIcons = true;
      modules.icons = { };
    };
    dropbar.enable = true;
    zen-mode.enable = true;
    nvim-autopairs.enable = true;
    noice.enable = true;

    which-key.enable = true;

    hlchunk = {
      enable = true;
      settings = {
        chunk.enable = true;
        indent.enable = true;
        line_num.enable = true;
      };
    };
  };
}
