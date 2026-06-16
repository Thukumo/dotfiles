{
  desktopLib,
  ...
}:

{
  config = {
    home-manager.users = desktopLib.mkHome (user: user.custom.desktop.ime or null == "skk") (
      _:
      { pkgs, ... }:
      {
        systemd.user.services."fcitx5-daemon".Services = {
          WatchDogSec = "10s";
          Restart = "always";
        };
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
                    Rule = "custom-no-kuten";
                    InitialInputMode = "Latin";
                    EggLikeNewLine = true;
                  };
                };
              };
            };
          };
        };
        xdg.configFile."libskk/rules/custom-no-kuten".source =
          let
            defaultRuleBase = "${pkgs.libskk}/share/libskk/rules/default";
            baseKeyMap = builtins.fromJSON (builtins.readFile "${defaultRuleBase}/keymap/default.json");
            fixedKeyMap = baseKeyMap // {
              define = baseKeyMap.define // {
                keymap = removeAttrs baseKeyMap.define.keymap [ "\\" ];
              };
            };
            customRuleName = "custom-no-kuten";
            meta = {
              name = customRuleName;
              description = "";
            };
          in
          pkgs.symlinkJoin {
            name = "libskk-rule-${customRuleName}";
            paths = [
              (pkgs.writeTextDir "keymap/default.json" (builtins.toJSON fixedKeyMap))
              (pkgs.writeTextDir "metadata.json" (builtins.toJSON meta))

              defaultRuleBase
            ];
          };
      }
    );
  };
}
