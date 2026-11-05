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
        email = if myConfig.email != null then myConfig.email else "${config.home.username}@localhost";
      }
      // lib.optionalAttrs myConfig.shell.private.enable {
        signingkey = "~/.ssh/id_ed25519.pub";
      };
      gpg.format = "ssh";
      "gpg \"ssh\"" = {
        program = "ssh-keygen";
        allowedSignersFile = "${pkgs.writeText "allowedSigners" ''
          ${user.email} ${lib.trim (builtins.readFile ../ssh/id_ed25519.pub)}
        ''}";
      };
      commit.gpgsign = myConfig.shell.private.enable;
      tag.gpgsign = myConfig.shell.private.enable;

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
