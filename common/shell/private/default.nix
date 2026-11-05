{ config, ... }:
{
  age.identityPaths = [ "${config.home.homeDirectory}/.config/age/home-manager_key" ];

  xdg.configFile."nix/nix.conf".text = ''
    !include ~/.config/nix/access-tokens
  '';

  home.file.".ssh/id_ed25519.pub".source = ../ssh/id_ed25519.pub;
}
