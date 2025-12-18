{ lib, config, ... }:

{
  options.custom.desktop.ime = {
    type = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "skk" ]);
      default = lib.mapNullable (_: "skk") config.custom.desktop.type;
    };
  };
  config = lib.mkMerge [
    (lib.mkIf (config.custom.desktop.ime.type == "skk") {
      home-manager.users."tsukumo" = { pkgs, ... } :{
        i18n.inputMethod = {
          enable = true;
          type = "fcitx5";
          fcitx5 = {
            waylandFrontend = true;
            addons = with pkgs; [
              fcitx5-gtk
              fcitx5-skk
              skkDictionaries.ml
              skkDictionaries.emoji
            ];
            settings = {
              inputMethod = {
                GroupOrder."0" = "Default";
                "Groups/0" = {
                  Name = "Default";
                  "Default Layout" = "jp";
                  "DefaultIM" = "skk";
                };
                "Groups/0/Items/0".Name = "skk";
              };
              addons = {
                skk = {
                  globalSection = {
                    # Rule = "azik";
                    InitialInputMode = "Latin";
                    EggLikeNewLine = true;
                  };
                };
              };
            };
          };
        };
      };
    })
  ];
}
