{ pkgs, ... }:

{
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
          # "Groups/0/Items/0".Name = "keyboard-jp";
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
  # xdg.configFile."fcitx5/conf/skk.conf".text = ''
  #   [General]
  #   Rule=azik
  #   # # 以下は好みで設定（句読点の扱いなど）
  #   # PunctuationStyle=Ja
  #   # PageSize=5
  # '';
}

