{
  myConfig,
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.git = {
    enable = true;
    settings = rec {
      user = {
        name = config.home.username;
        email = myConfig.email or "${config.home.username}@localhost";
        signingkey = "~/.ssh/id_ed25519.pub";
      };
      gpg.format = "ssh";
      "gpg \"ssh\"" = {
        program = "ssh-keygen";
        allowedSignersFile = "${pkgs.writeText "allowedSigners" ''
          ${user.email} ${lib.trim (builtins.readFile ../ssh/id_ed25519.pub)}
        ''}";
      };
      commit.gpgsign = true;
      tag.gpgsign = true;

      core.editor = "nvim";
      push.autoSetupRemote = true;
    };
  };
  programs.gh = {
    enable = true;
    settings = {
      editor = "nvim";
    };
  };
  programs.lazygit = {
    enable = true;
    settings = {
      disableStartupPopups = true;
    };
  };
}
