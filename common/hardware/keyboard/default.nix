{
  config,
  lib,
  myLib,
  ...
}:
let
  myConfig = config.custom.hardware.keyboard;
in
{
  options.custom.hardware.keyboard = {
    keybind = {
      enable = myLib.mkEnabledOption;
      deviceIds = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "List of keyboard device IDs to apply keybindings to. Use '*' for all keyboards.";
        example = [ "0001:0001" ];
      };
    };
    vialRule.enable = myLib.mkEnabledOption;
  };
  config = {
    # for vial
    services.udev.extraRules = lib.mkIf myConfig.vialRule.enable ''
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0666", TAG+="uaccess", TAG+="udev-acl"
    '';

    services.keyd = {
      enable = myConfig.keybind.enable;
      keyboards.default = {
        ids = myConfig.keybind.deviceIds;
        settings = {
          main = {
            capslock = "overload(meta, tab)";
            shift = "overload(shift, esc)";
            muhenkan = "home";
            henkan = "end";
            katakanahiragana = "end";
            space = "overload(nav, space)";
            tab = "/";
          };
          nav = {
            h = "left";
            k = "up";
            j = "down";
            l = "right";
            ";" = "backspace";
          };
          "nav+meta" = {
            h = "home";
            l = "end";
          };
        };
      };
    };
  };
}
