{
  config,
  lib,
  pkgs,
  ...
}:
{
  config =
    let
      isEnabled = builtins.any (user: user.desktop.vr.immersed.enable or false) (
        builtins.attrValues config.custom.users
      );
    in
    lib.mkIf isEnabled {
      programs.immersed.enable = true;
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
          libva
          libva-vdpau-driver
        ];
      };
    };
}
