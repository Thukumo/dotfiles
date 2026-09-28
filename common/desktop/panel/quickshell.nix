{
  config,
  lib,
  pkgs,
  desktopLib,
  ...
}:

let
  colors = config.lib.stylix.colors.withHashtag;

  panelInfo = pkgs.writeShellApplication {
    name = "panel-info";
    runtimeInputs = with pkgs; [
      acpi
      coreutils
      gawk
      gnused
      iproute2
      iw
      procps
      wireplumber
    ];
    text = builtins.readFile ./panel-info.sh;
  };

  themeJs = ''
    .pragma library

    var base00 = "${colors.base00}";
    var base01 = "${colors.base01}";
    var base02 = "${colors.base02}";
    var base03 = "${colors.base03}";
    var base04 = "${colors.base04}";
    var base05 = "${colors.base05}";
    var base06 = "${colors.base06}";
    var base07 = "${colors.base07}";
    var base08 = "${colors.base08}";
    var base09 = "${colors.base09}";
    var base0A = "${colors.base0A}";
    var base0B = "${colors.base0B}";
    var base0C = "${colors.base0C}";
    var base0D = "${colors.base0D}";
    var base0E = "${colors.base0E}";
    var base0F = "${colors.base0F}";

    var fontSans = "${config.stylix.fonts.sansSerif.name}";
    var fontMono = "${config.stylix.fonts.monospace.name}";

    var infoCmd = "${panelInfo}/bin/panel-info";
    var curl = "${pkgs.curl}/bin/curl";
  '';
in
{
  config = lib.mkIf config.custom.desktop.anyEnabled {
    home-manager.users = desktopLib.mkHome (user: user.custom.desktop.panel == "quickshell") (_: {
      programs.quickshell = {
        enable = true;
        systemd.enable = true;
        activeConfig = "panel";
      };

      xdg.configFile = {
        "quickshell/panel/shell.qml".source = ./shell.qml;
        "quickshell/panel/Theme.js".text = themeJs;
      };
    });
  };
}
