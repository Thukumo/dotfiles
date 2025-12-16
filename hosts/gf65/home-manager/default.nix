{ pkgs, ... }:

{
  # Host-specific home-manager configuration for thinkpadx13-nix

  # Additional packages specific to this host
  home.packages = with pkgs; [
    # Add host-specific packages here
  ];

  # Host-specific configurations
  # home.sessionVariables = {
  #   # Add host-specific environment variables
  # };

  # Host-specific files
  # home.file = {
  #   # Add host-specific file configurations
  # };
}
