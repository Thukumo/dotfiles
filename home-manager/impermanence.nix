{ config, pkgs, ... }:

{
  home.persistence."/persist/${config.home.homeDirectory}" = {
    directories = [
        "Documents"
        "dotfiles"
        ".gemini"
        ".config/google-chrome"
        ".config/discord"
        ".config/Mattermost"
        ".local/share/fish"
        ".local/state/wireplumber"
        # ".local/share/affinity-v3"
        ".ssh" # known_hosts用
    ];
    files = [
    ];
    allowOther = true;
  };
}
