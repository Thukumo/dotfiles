{
  lib,
  config,
  myLib,
  pkgs,
  ...
}:

{
  options.custom.users = myLib.mkUserOption {
    options.dev.antigravity = {
      enable = lib.mkEnableOption "Google Antigravity";
    };
  };
  config = lib.mkIf (myLib.anyUser config (user: user.dev.antigravity.enable)) {
    nixpkgs.config.allowUnfreePackages = [ pkgs.antigravity-ide.pname ];
    home-manager.users = myLib.mkForEachUsers config (user: user.custom.dev.antigravity.enable) (
      _:
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.antigravity-ide
        ];
        home.persistence."/persist".directories = [
          ".antigravity"
          ".config/Antigravity"
        ];
      }
    );
  };
}
