{
  config,
  lib,
  myLib,
  ...
}:
{
  imports = [
    ./vial.nix
  ];
  options.custom.keybind = {
    enable = myLib.mkEnabledOption;
    deviceIds = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of keyboard device IDs to apply keybindings to. Use '*' for all keyboards.";
      example = [ "0001:0001" ];
    };
  };
  config = lib.mkIf config.custom.keybind.enable {
    services.keyd = {
      enable = true;
      keyboards.default = {
        ids = config.custom.keybind.deviceIds;
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
