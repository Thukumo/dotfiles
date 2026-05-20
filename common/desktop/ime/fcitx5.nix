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
        home.file =
          let
            defaultRuleBase = "${pkgs.libskk}/share/libskk/rules/default";
            customRuleName = "custom-no-kuten";
            customRuleDir =
              pkgs.runCommandLocal "libskk-rule-${customRuleName}" { nativeBuildInputs = [ pkgs.jq ]; }
                ''
                  cp -r --no-preserve=mode ${defaultRuleBase}/. "$out"
                  ${pkgs.jq}/bin/jq 'del(.define.keymap["\\"])' "$out/keymap/default.json" > "$out/keymap/default.json.new"
                  mv "$out/keymap/default.json.new" "$out/keymap/default.json"
                  cat > "$out/metadata.json" <<'EOF'
                  {
                    "name": "${customRuleName}",
                    "description": "Default rule without kuten on backslash"
                  }
                  EOF
                '';
            customRuleBase = ".config/libskk/rules/${customRuleName}";
          in
          {
            "${customRuleBase}".source = customRuleDir;
          };
      }
    );
  };
}
