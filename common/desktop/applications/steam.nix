{
  config,
  lib,
  desktopLib,
  myLib,
  pkgs,
  ...
}:

{
  config = lib.mkIf (myLib.anyUser config (user: user.desktop.apps.steam.enable)) {
    nixpkgs.config.allowUnfreePackages = [
      pkgs.steam.pname
      pkgs.steam-unwrapped.pname
    ];
    hardware.graphics.enable32Bit = true;
    programs.steam = {
      enable = true;
      extest.enable = true;
      remotePlay.openFirewall = true;
      fontPackages = with pkgs; [ ipaexfont ];
      package = pkgs.steam.override {
        extraArgs = "-language japanese";
        extraEnv = {
          MANGOHUD = true;
          PROTON_ENABLE_NVAPI = 1;
        };
      };
    };
    home-manager.users = desktopLib.mkHome (user: user.custom.desktop.apps.steam.enable) (_: {
      programs.mangohud = {
        enable = true;
        enableSessionWide = true;
        settings = {
          full = true;
          no_display = true;
        };
      };
      custom.desktop.persistDesktopEntries = true;
      home.persistence."/persist".directories = [
        ".local/share/Steam"
      ];
    });
  };
}
