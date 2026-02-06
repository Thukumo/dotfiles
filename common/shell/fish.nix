{ pkgs, ... }:

{
  programs.fish = {
    enable = true;
  };
  # home.sessionPath = [
  #   "$HOME/.cargo/bin"
  # ];
  home.shell.enableFishIntegration = true;
  home.shellAliases = {
    ls = "${pkgs.lsd}/bin/lsd";
    # cat = "${pkgs.bat}/bin/bat";
    # nano = "${pkgs.micro-full}/bin/micro";
    pres = "${pkgs.gnutar}/bin/tar -I 'zstd -T0'";
    sl = "nix shell";
  };
}
