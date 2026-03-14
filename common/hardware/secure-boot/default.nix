{ config, lib, ... }:

{
  imports = [
    ./lanzaboote.nix
    ./tpm2-totp.nix
  ];

  options.custom.hardware.secure-boot = {
    enable = lib.mkEnableOption "Secure Boot support";
  };
}
