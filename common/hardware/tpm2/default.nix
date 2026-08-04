{ lib, ... }:
{
  security.tpm2.enable = lib.mkDefault true;
}
