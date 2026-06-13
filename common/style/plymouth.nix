{
  pkgs,
  config,
  lib,
  myLib,
  ...
}:
let
  myConfig = config.custom.style.plymouth;
in
{
  options.custom.style.plymouth = {
    enable = myLib.mkEnabledOption;
    theme = lib.mkOption {
      type = lib.types.str;
      default = "hellonavi";
    };
    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = with pkgs; [
        (stdenvNoCC.mkDerivation {
          name = "hellonavi";
          src = builtins.fetchGit {
            url = "https://github.com/yi78/hellonavi";
            ref = "master";
            rev = "a369222fc7943e0ad59be710a5c6cf6b0137f309";
          };
          patchPhase = ''
            sed -i 's/dialog_opacity (0);/&\n      navi.sprite.SetOpacity (1);/' hellonavi/hellonavi.script
          '';
          installPhase = ''
            THEME_DIR=$out/share/plymouth/themes
            mkdir -p $THEME_DIR
            mv hellonavi $THEME_DIR/hellonavi
            find $THEME_DIR/ -name \*.plymouth -exec sed -i "s@\/usr\/@$out\/@" {} \;
          '';
        })
      ];
    };
  };
  config = lib.mkIf myConfig.enable {
    stylix.targets.plymouth.enable = false;
    boot = {
      consoleLogLevel = 3;
      plymouth = {
        enable = true;
        inherit (myConfig) theme;
        themePackages = myConfig.packages;
        tpm2-totp.enable = config.custom.hardware.secure-boot.tpm2-totp.enable;
      };
    };
  };
}
