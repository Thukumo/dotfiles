{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    xremap
    wtype
  ];
  imports = [
    ./config.nix
  ];
 systemd.user.services.xremap = {
    Unit = {
      Description = "xremap auto start";
    };
    Service = {
      ExecStart = "${pkgs.xremap}/bin/xremap --watch ${config.home.homeDirectory}/.config/xremap/config.yml";
      Restart = "always";

    };
    restartTriggers = {
      config = builtins.toString config.xdg.configFile."xremap/config.yml".source;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
