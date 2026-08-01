{
  desktopLib,
  inputs,
  pkgs,
  ...
}:
let
  inherit ((builtins.fromJSON (builtins.readFile "${inputs.sidra}/package.json"))) version;
  # sidra is shipped as a prebuilt deb (CastLabs VMP-signed for Widevine);
  # we repackage it and patch the bundled app.asar to fall back to
  # getShareUrl() for xesam:url (see sidra-linux.nix)
  sidra = pkgs.callPackage ./sidra/linux.nix { inherit version; };
in
{
  config = {
    home-manager.users = desktopLib.mkHome (user: user.custom.desktop.apps.sidra.enable or false) (
      _: _: {
        home.packages = [ sidra ];
        home.persistence."/persist".directories = [
          ".config/Sidra"
        ];
      }
    );
  };
}
