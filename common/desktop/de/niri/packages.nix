{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nautilus # For GNOME portal file chooser
    xwayland-satellite
  ];
}
