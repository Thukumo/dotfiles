{ config, pkgs, lib, ... }:

{
  options.users.users = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options.custom = {
        email = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "User's email address for git configuration and other uses";
        };
      };
    });
  };

  config = {
    users.mutableUsers = false;

    users.users."tsukumo" = {
      isNormalUser = true;
      hashedPasswordFile = "/run/agenix/passwd_tsukumo";
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
      shell = pkgs.fish;
      
      # Custom User Configuration
      custom = {
        email = "contact@tsukumo.f5.si";
        secrets.secretKey = "/home/tsukumo/.ssh/id_ed25519"; 
        
        desktop = {
          type = "niri";
          term.type = "foot";
          launcher.type = "fuzzel";
          ime.type = "skk";
          apps = {
            chromium.enable = true;
            discord.enable = true;
            google-chrome.enable = true;
            mattermost-desktop.enable = true;
            steam.enable = true;
            libreoffice.enable = true;
            zoom.enable = true;
            gnome-disk-utility.enable = true;
            rquickshare.enable = true;
            thunar.enable = true;
          };
        };
        
        dev.podman.enable = true;
      };
    };
    # for shell
    programs.fish.enable = true;

    security.sudo.wheelNeedsPassword = false;
  };
}
