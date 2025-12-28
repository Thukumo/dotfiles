{ config, lib, ... }:
{
  options.custom.keybind = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };
  config = lib.mkIf config.custom.keybind.enable {
    services.keyd = {
      enable = true;
      keyboards.default = {
        ids = [ "*" ];
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
