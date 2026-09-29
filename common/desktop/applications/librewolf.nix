{
  desktopLib,
  ...
}:
{
  config = {
    home-manager.users = desktopLib.mkHome (user: user.custom.desktop.apps.librewolf.enable) (
      user:
      { lib, ... }:
      let
        extensions = [
          # duplicate-tabs-closer
          "jid0-RvYT2rGWfM8q5yWxIxAHYAeo5Qg@jetpack"
        ]
        ++ user.custom.desktop.apps.librewolf.extensions;
      in
      {
        programs.librewolf = {
          enable = true;
          languagePacks = [ "ja" ];
          policies = {
            RequestedLocales = [ "ja" ];
            Preferences."intl.accept_languages" = "ja,ja-JP";

            ExtensionSettings = {
              "*" = {
                installation_mode = "blocked";
                blocked_install_message = "dotfiles で宣言していない拡張機能はインストールできません";
              };
            }
            // lib.genAttrs extensions (id: {
              installation_mode = "normal_installed";
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/${id}/latest.xpi";
            });
          };
        };
        home.persistence."/persist".directories = [
          ".config/librewolf"
        ];
      }
    );
  };
}
