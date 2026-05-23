{
  config,
  pkgs,
  ...
}:

{
  imports = [
    ./home-activate-linux.nix
    ./packages.nix
    ./mako.nix
    ./swayosd.nix
    ./binds.nix
  ];

  programs.niri = {
    enable = true;
    package = pkgs.niri.overrideAttrs (_old: {
      doCheck = false;
      checkPhase = "";
    });
    settings = {
      prefer-no-csd = true;
      hotkey-overlay.skip-at-startup = true;

      animations = {
        slowdown = 0.5;
        window-open.enable = false;
        window-close.enable = false;
        window-resize.enable = false;
      };

      gestures.hot-corners.enable = false;
      input = {
        mod-key = "Super";
        keyboard = {
          repeat-delay = 400;
          xkb.layout = "jp";
        };
        touchpad = {
          dwt = true;
          tap = true;
        };
      };
      cursor = {
        hide-when-typing = true;
        hide-after-inactive-ms = 1000;
      };
      layout = {
        default-column-width.proportion = 0.5;
        gaps = 8;
      };
      spawn-at-startup = [
        # fcitx5は、autostartにファイルがあるから不要っぽい
        {
          command = [
            "${pkgs.swaybg}/bin/swaybg"
            "-i"
            config.stylix.image
          ];
        }
      ];
    };
  };

  services.batsignal = {
    enable = true;
    extraArgs = [ "-p" ];
  };
}
