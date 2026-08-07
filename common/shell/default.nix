{
  lib,
  myLib,
  config,
  pkgs,
  ...
}:

{
  options.custom.users = myLib.mkUserOption {
    options.shell.private.enable = lib.mkEnableOption "private shell secrets";
  };

  config = {
    home-manager.users = lib.mkMerge [
      (myLib.mkForEachUsers config (_: true) (_: {
        imports = myLib.mkImportModules ./. [ "private" ];
      }))
      (myLib.mkForEachUsers config (user: user.custom.shell.private.enable) (_: {
        imports = [ ./private ];
      }))
    ];

    nixpkgs.config.allowUnfreePackages = [
      pkgs.github-copilot-cli.pname
      pkgs.antigravity-cli.pname
    ];
  };
}
