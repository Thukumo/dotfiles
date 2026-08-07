{
  config,
  lib,
  pkgs,
  myLib,
  ...
}:
{
  config =
    let
      isEnabled = myLib.anyUser config (user: user.desktop.vr.immersed.enable);
    in
    lib.mkIf isEnabled {
      nixpkgs.config.allowUnfreePackages = [ pkgs.immersed.pname ];
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
